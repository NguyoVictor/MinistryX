CREATE USER IF NOT EXISTS 'churchcrm'@'%' IDENTIFIED BY 'changeme';
GRANT ALL PRIVILEGES ON churchcrm.* TO 'churchcrm'@'%';
FLUSH PRIVILEGES;