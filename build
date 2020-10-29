# Update the following if you're not using DigitalOcean
apiRoot="/var/www/html/e28/e28-api"
user='www-data'



#
# Output
#
function dump {
    echo ""
    echo "===> $1"
} 


#
# Detect environment
#
if [ -d $apiRoot ]; then
    environment="production"
else
    environment="local"
fi

dump "Detected environment: $environment"


#
# Update code
#
dump "Updating e28-api-core"

# Make core directory if it doesn't exist
mkdir -p core

# All other commands should be run in core/
cd core

# Update e28-api-core if it already exists (`app` directory present)
if [ -d "app" ]; then
    git pull
# Clone e28-api-core if it does not yet exist
else
    git clone git@github.com:susanBuck/e28-api-core.git .
fi


#
# Packages
#
if [ $environment == 'production' ]; then

    # If we have sqlite3, we can assume server prep has already been completed - skip
    if php -m | grep sqlite3 >/dev/null; then
        dump "Server already prepped to run Laravel application"
    else
        dump "Prepping server to run Laravel application"

        echo "Adding modules"
        sudo add-apt-repository ppa:ondrej/php
        sudo apt-get update
        sudo apt-get install php7.4-mbstring zip unzip php7.4-xml php-sqlite3

        echo "Enabling modrewrite"
        # Laravel requires Apache's `mod_rewrite` for URL routing, so we enable it:
        sudo a2enmod rewrite

        echo "Restarting Apache"
        service apache2 restart
    fi
fi


#
# Database
#
dump "Setting up database"
touch database/database.sqlite
if [ $environment == 'production' ]; then
    # the PDO SQLite driver requires that if you are going to do a write operation (INSERT, UPDATE, DELETE, DROP, etc.),
    # then the folder the database resides in must have write permissions, as well as the actual database file
    chown -R ${user} "${apiRoot}/core/database"
fi

# Do initial migration (so sessions and other fundamental tables exist, allowing artisan scripts to run w/o error)
php artisan migrate --force

#
# Laravel initial setup
#
if [ ! -f ".env" ]; then
    dump "Laravel initial setup"

    echo "Creating environment file (.env)"
    cp .env.example .env
    
    echo "Generating app key"
    php artisan key:generate
fi


#
# Permissions
#
if [ $environment == 'production' ]; then
    dump "Setting permissions"
    chown -R ${user} "${apiRoot}/core/storage"
    chown -R ${user} "${apiRoot}/core/bootstrap/cache"
    chown -R ${user} "${apiRoot}/core/database/migrations/"
    chown -R ${user} "${apiRoot}/core/database/factories/GeneratedModels"
    chown -R ${user} "${apiRoot}/core/app/Models/GeneratedModels/"
    chown -R ${user} "${apiRoot}/core/app/Http/Controllers/GeneratedControllers/"
    chown -R ${user} "${apiRoot}/core/app/Http/Requests/GeneratedRequests/"
    chown -R ${user} "${apiRoot}/core/database/factories/GeneratedModels"
    chown -R ${user} "${apiRoot}/core/routes"
fi


if [ $environment == 'production' ]; then
    url="e28-api.yourdomain.com"
else
    url="e28-api.loc"
fi

dump "Expected Virtual Host:"
echo "
<VirtualHost *:80>
    ServerName $url
    DocumentRoot $(pwd)/public/
    <Directory $(pwd)/public/>
        AllowOverride All
        Options -Indexes
        Require all granted
    </Directory>
</VirtualHost>
"


#
# Build API
#
dump "Build API"
php artisan e28-api:build