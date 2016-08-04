# VFT Sim

The VFT Sim app is a web interface for simulating the weld process designed by
[Emc2](http://www.emc-sq.com/) utilizing [OSC](https://www.osc.edu/) resources.

## Deployment

1.  Based on deployment location you will need to determine the URI used to
    access this app, e.g.:

    ```
   /awesim_dev/shared_apps/awe0011/vftwebapp_v2
    ```

2.  Update the `.env.production` with corresponding deployment location and URI
    information.

3.  Copy over and modify the `.htaccess` file:

    ```
    cp public/.htaccess.production public/.htaccess
    vim public/.htaccess
    ```

4.  Create a matching directory under the shared apps root `.tmp/`:

    ```
    mkdir ../.tmp/vftwebapp_v2
    touch ../.tmp/vftwebapp_v2/restart.txt
    ```

5.  Create a symlink for your app directory under the shared apps root `.apps/`:

    ```
    ln -s ../vftwebapp_v2/public ../.apps/vftwebapp_v2
    ```

6.  Remove permissions to access this app:

    ```
    chmod 750 ../vftwebapp_v2
    ```

7.  Add permissions to who ever you want to access this app:

    ```
    nfs4_setfacl -a A::<user>@osc.edu:rx ../vftwebapp_v2
    nfs4_setfacl -a A:g:<group>@osc.edu:rx ../vftwebapp_v2
    ```

8.  Bundle install gems:

    ```
    bin/bundle install --path=vendor/bundle
    ```

9.  Compile assets:

    ```
    bin/rake assets:clobber RAILS_ENV=production
    bin/rake assets:precompile RAILS_ENV=production
    bin/rake tmp:clear RAILS_ENV=production
    ```

10. Restart the app for users:

    ```
    touch ../.tmp/vftwebapp_v2/restart.txt
    ```

## Development

1.  Git clone down this project

2.  Set up the `.htaccess` file:

    ```
    cat public/.htaccess.development public/.htaccess.passenger_fix > public/.htaccess
    ```

3.  Bundle install gems:

    ```
    bin/bundle install --path=vendor/bundle
    ```

4.  Setup the development database:

    ```
    bin/rake db:setup
    ```
