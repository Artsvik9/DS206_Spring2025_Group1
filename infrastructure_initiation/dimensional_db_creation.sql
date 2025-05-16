IF DB_ID('ORDER_DDS') IS NULL
BEGIN
    CREATE DATABASE ORDER_DDS;
    PRINT 'Database ORDER_DDS created successfully.';
END
ELSE
BEGIN
    PRINT 'Database ORDER_DDS already exists.';
END