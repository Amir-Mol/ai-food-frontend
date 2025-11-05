class AppConfig {

  static const String googleWebClientId = "1509705759-e40djp41nc3d8cadihmjrejg7nrjsglq.apps.googleusercontent.com";
  
  // --- The Switch ---
  // Set to 'false' for local development (to use 10.0.2.2)
  // Set to 'true' for production (to use the live Render URL)
  static const bool isProduction = true; 

  // --- URLs ---
  static const String _productionUrl = 'https://ai-food-backend-m8ty.onrender.com';
  static const String _developmentUrl = 'http://10.0.2.2:8000';

  // --- The Final URL ---
  // This line automatically chooses the correct URL based on the switch
  static const String apiBaseUrl = isProduction ? _productionUrl : _developmentUrl;
}