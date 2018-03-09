# Vagrant Install Guide

### Getting Started

1. Install Git
2. Install VirtualBox: https://www.virtualbox.org/wiki/Downloads
3. Install Vagrant: https://www.vagrantup.com/downloads.html
4. Open a terminal
5. Clone the project: `git clone https://github.com/ReseauEntourage/entourage-ror.git`
6. Enter the project directory: `cd entourage-ror`


### Local Hostnames Setup

Some features of the Entourage backend app are only accessible through an `admin.*` subdomain. One way of setting this up is to edit your [hosts file] to have the `admin.entourage.local` hostname resolve to your computer.

```bash
$ sudo vim /etc/hostname
```

Then, tap on the `i` key and use the arrow keys on your keyboard to navigate the text area. Modify your hosts file so that it resembles the following:

```
127.0.0.1 localhost entourage.local admin.entourage.local
```

To save and exit, tap the `Esc` key, on your keyboard, followed by these keystrokes: `:`, `w`, `q`, and, finally, `Enter`.

[hosts file]: https://en.wikipedia.org/wiki/Hosts_(file)


### Using Vagrant

When you're ready to start working, boot the VM:
```bash
$ vagrant up
```

The first time that you run it, this command will take a few minutes to complete, because it has a lot of set up to do.

Once the virtual machine has booted up, you can shell into it by typing:

```bash
$ vagrant ssh
```

Now you're in a virtual machine, almost ready to start developing.
The Entourage code is found in the `entourage-ror` directory:

```bash
$ cd entourage-ror
```


### Starting Rails

You can start a rails instance using the following command from the `~/entourage-ror` directory:

```bash
$ bundle exec rails server -b 0.0.0.0
```

In a few seconds, rails will start serving pages. To access them, open a web browser to http://entourage.local:4000 - if it all worked you should see the Entourage app! Congratulations, you are ready to start working!

You can now edit files on your local file system, using your favorite text editor or IDE. When you reload your web browser, it should have the latest changes.


### Creating an Admin User

You'll want an admin account to be able to do anything fun on your new Entourage environment. Enter your Vagrant image by using `vagrant ssh` then
run the following command to open a console that will let you interact with the Rails application from the command line:

```bash
$ bundle exec rails console
```

In this console, execute the following Ruby code:
```ruby
require 'factory_girl'
require_relative 'spec/factories/users.rb'
FactoryGirl.create :public_user, admin: true, phone: "+33600000001", sms_code: "123123"
```

This creates an admin account with the phone number `+33600000001` and the SMS code `123123`.
Then type `Ctrl`+`D` to leave this console.

Ensure that you have started the Rails server, and open http://admin.entourage.local:4000/sessions/new in your browser.
Log in with the credentials, and head to http://admin.entourage.local:4000/admin to access the admin interface.


### Shutting down the VM

When you're done working on the Entourage app, you can log out of the virtual machine, then shut down Vagrant with:

``` bash
$ vagrant halt
```
