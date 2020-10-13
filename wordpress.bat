drop database if exists db;
create database db;
grant all privileges on db.* to username@localhost identified by 'password';
flush privileges;
