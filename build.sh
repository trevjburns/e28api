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
if [ -d "/var/www/html" ]; then
    environment="production"
else
    environment="local"
fi

dump "Detected environment: $environment"


#
# Update code
#
dump "Syncing code with github.com/susanBuck/e28-api"
git pull


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

        # echo "Installing Composer"
        # apt install composer

        echo "Enabling modrewrite"
        # Laravel requires Apache's `mod_rewrite` for URL routing, so we enable it:
        sudo a2enmod rewrite

        echo "Restarting Apache"
        service apache2 restart
    fi
fi


cd "core"


#
# Database
#
dump "Setting up database"
touch database/database.sqlite
if [ $environment == 'production' ]; then
    # the PDO SQLite driver requires that if you are going to do a write operation (INSERT, UPDATE, DELETE, DROP, etc.),
    # then the folder the database resides in must have write permissions, as well as the actual database file
    chown -R www-data /var/www/html/e28-api/core/database
fi


# Do initial migration (so sessions and other fundamental tables exist, allowing artisan scripts to run w/o error)
# Note: Build API command does a migration:fresh to run all migrations that it adds
php artisan migrate --force


#
# Laravel stufff
#
dump "Creating environment file (.env)"
cp .env.example .env


dump "Generating app key"
php artisan key:generate


#
# Permissions
#
if [ $environment == 'production' ]; then
    dump "Setting permissions"
    chown -R www-data /var/www/html/e28-api/core/storage
    chown -R www-data /var/www/html/e28-api/core/bootstrap/cache
    chown -R www-data /var/www/html/e28-api/core/database/migrations/
    chown -R www-data /var/www/html/e28-api/core/app/Models/GeneratedModels/
    chown -R www-data /var/www/html/e28-api/core/app/Http/Controllers/GeneratedControllers/
    chown -R www-data /var/www/html/e28-api/core/routes
fi


#
# Build API
#
dump "Build API"
php artisan e28-api:build


dump "Setup complete"