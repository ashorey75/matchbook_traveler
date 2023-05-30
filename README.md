Ruby Version:
Ruby 2.6.3p62

Browser:
Google Chrome Version 110.0.5481.105 (Official Build) (64-bit)

Database:
(PostgreSQL) 9.2.24


Description:
Matchbook Traveler is designed to document the locations of bars and/or restaurants
that provide matchbooks to its patrons. This application is beneficial for matchbook 
hobbyists as they are able to update a log of locations to share with like-minded
individuals. This application allows the functionality to add cities into its database
and display as such as well as add matchbook locations within those cities, 
with descriptors of the bar/restaurant name, address, neighborhood, as well as 
whether or not the location provides generic matchbooks or has custom visuals on
the matchbook that reflects details of the business in which it was received.


Application Instructions:
In order to run this application, make sure that the application is downloaded to your terminal.
Make sure that the proper gems and dependencies are installed as well.
Make sure you have Ruby 2.6.3p62 installed on your computer. 
You can check your version of Ruby by running ruby -v in your terminal.
If you have multiple versions of ruby make sure that you have the correct version assigned using rvm or whichever your preferred version manager is.
If you don't have Ruby installed, you can download it from the official website for your operating system.
Install Google Chrome Version 110.0.5481.105 (Official Build) (64-bit) if it is not already installed on your computer.
Install PostgreSQL version 9.2.24. You can download it from the official PostgreSQL website for your operating system. 
Install the sinatra version 1.4.7 gem by running gem install sinatra -v 1.4.7 in your terminal.
Install the pg gem version 0.18.4 by running gem install pg -v 0.18.4 in your terminal.
Once you have installed all the necessary dependencies, navigate to the directory where the application is stored in your terminal.
We can also execute the Gemfile by calling bundle install in the terminal.
We should also start PostgreSQL before running the application. This is done using sudo service postgresql start for cloud9 
The database for this project should also be created. This can be done by entering PostgreSQL using the command psql from the terminal
Once there, the following code should be run `CREATE DATABASE matchbook;`to create the database.
From there, we can exit postgresql using `\q`
We are going to reenter postgresql, making sure that we are in the `matchbook_traveler` folder and running the following to uplod the `.sql` file into the database
`psql -d matchbook < schema.sql`
Run the command ruby matchbook_traveler.rb to start the application. This should launch the application in your web browser.
Feel free to use the existing username/password 'admin' and 'password' for the demonstration or create your own 


