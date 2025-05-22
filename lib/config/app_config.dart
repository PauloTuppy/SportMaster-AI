class AppConfig {
  // OpenSearch Configuration
  static const String opensearchEndpoint = 'YOUR_OPENSEARCH_ENDPOINT_HERE';
  static const String opensearchRegion = 'YOUR_OPENSEARCH_REGION_HERE';
  static const String opensearchAccessKey = 'YOUR_OPENSEARCH_ACCESS_KEY_HERE';
  static const String opensearchSecretKey = 'YOUR_OPENSEARCH_SECRET_KEY_HERE';

  // Generic API Service Configuration (for services like Embedding, ImageAnalysis, SocialMedia, DataPipeline, HealthAgent, AgentIntegration)
  static const String genericApiBaseUrl = 'https://api.sportmaster.ai'; // Common base URL observed
  static const String genericApiKey = 'YOUR_GENERIC_API_KEY_HERE'; // Placeholder for services needing an API key

  // AutoGen Service Configuration
  static const String autogenApiBaseUrl = 'https://api.sportmaster.ai/autogen';
  // Note: AutoGenService didn't explicitly take an API key in its original form,
  // but if it needs one, it can use genericApiKey or have its own.
  // static const String autogenApiKey = 'YOUR_AUTOGEN_API_KEY_HERE';

  // LangGraph Service Configuration
  static const String langgraphApiBaseUrl = 'https://api.sportmaster.ai/langgraph';
  // Note: LangGraphService also didn't explicitly take an API key.
  // static const String langgraphApiKey = 'YOUR_LANGGRAPH_API_KEY_HERE';

  // Monitoring Service Configuration
  // Assuming MonitoringService might also use the genericApiBaseUrl or its own specific one.
  // For now, let's assume it uses the generic one if not specified otherwise.
  static const String monitoringApiBaseUrl = 'https://api.sportmaster.ai/monitoring'; // Or use genericApiBaseUrl
  static const String monitoringApiKey = 'YOUR_MONITORING_API_KEY_HERE'; // Or use genericApiKey

  // Add other specific configurations as needed, for example, if some services
  // under genericApiBaseUrl use different API keys.
  // For example, if ImageAnalysisService had a unique key:
  // static const String imageAnalysisApiKey = 'YOUR_IMAGE_ANALYSIS_API_KEY';
}
