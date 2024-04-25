const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
const isDev = environment == 'dev';
const isProd = environment == 'prod';
