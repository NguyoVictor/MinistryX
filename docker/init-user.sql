-- Create ChurchCRM user if not exists
CREATE USER IF NOT EXISTS 'churchcrm'@'%' IDENTIFIED BY 'changeme';

-- Grant all privileges to ChurchCRM user on churchcrm database
GRANT ALL PRIVILEGES ON churchcrm.* TO 'churchcrm'@'%';

-- Apply changes
FLUSH PRIVILEGES;