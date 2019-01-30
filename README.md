# VFT Sim

The VFT Sim app is a web interface for simulating the weld process designed by
[Emc2](http://www.emc-sq.com/) utilizing [OSC](https://www.osc.edu/) resources.

## Deployment

1.  Git clone this project into the deployment location:

    ```sh
    scl enable git19 -- git clone git@github.com:AweSim-OSC/vftwebapp.git vftwebapp
    ```

2.  Update permissions of this app so that only registered users can access it:

    ```sh
    chmod 750 vftwebapp
    nfs4_setfacl -a A:g:emc2vft@osc.edu:rx vftwebapp
    ```

3.  Install the documentation:

    ```sh
    cd vftwebapp

    scl enable git19 -- git clone git@github.com:AweSim-OSC/vftwebapp.wiki.git wiki
    ```

4.  Run the update script to build the app:

    ```sh
    # Examples:
    #   ./update.sh v1.0.0
    #   ./update.sh master
    ./update.sh <tag>
    ```

## Update

1.  To update the app to a later tagged version, just run the update script
    specifying the version as an argument:

    ```sh
    # Examples:
    #   ./update.sh v1.0.0
    #   ./update.sh master
    ./update.sh <tag>
    ```

## Development

1.  Git clone this project into development directory and go into it:

    ```sh
    scl enable git19 -- git clone git@github.com:AweSim-OSC/vftwebapp.git vftwebapp

    cd vftwebapp
    ```

2.  Bundle install gems:

    ```sh
    scl enable git19 rh-ruby24 -- bin/bundle install --path=vendor/bundle
    ```

4.  Setup the development database:

    ```
    scl enable git19 rh-ruby24 -- bin/rake db:setup
    ```
