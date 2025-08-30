//! Middleware module for dia framework
//! 
//! Provides the Middleware trait and common middleware implementations.

use crate::{Request, Response};
use std::future::Future;
use std::pin::Pin;

/// Trait for implementing middleware
pub trait Middleware: Send + Sync {
    /// Process the request before it reaches the handler
    fn before_request(
        &self,
        req: &mut Request,
    ) -> Pin<Box<dyn Future<Output = Option<Response>> + Send>> {
        Box::pin(async { None })
    }

    /// Process the response after the handler
    fn after_request(
        &self,
        req: &Request,
        resp: Response,
    ) -> Pin<Box<dyn Future<Output = Response> + Send>> {
        Box::pin(async { resp })
    }

    /// Get middleware name for logging
    fn name(&self) -> &str {
        "unknown"
    }
}

/// CORS middleware for handling cross-origin requests
pub struct CorsMiddleware {
    /// Allowed origins
    allowed_origins: Vec<String>,
    /// Allowed methods
    allowed_methods: Vec<String>,
    /// Allowed headers
    allowed_headers: Vec<String>,
    /// Allow credentials
    allow_credentials: bool,
}

impl CorsMiddleware {
    /// Create a new CORS middleware with default settings
    pub fn new() -> Self {
        Self {
            allowed_origins: vec!["*".to_string()],
            allowed_methods: vec!["GET".to_string(), "POST".to_string(), "PUT".to_string(), "DELETE".to_string()],
            allowed_headers: vec!["*".to_string()],
            allow_credentials: false,
        }
    }

    /// Set allowed origins
    pub fn allowed_origins(mut self, origins: Vec<String>) -> Self {
        self.allowed_origins = origins;
        self
    }

    /// Set allowed methods
    pub fn allowed_methods(mut self, methods: Vec<String>) -> Self {
        self.allowed_methods = methods;
        self
    }

    /// Set allowed headers
    pub fn allowed_headers(mut self, headers: Vec<String>) -> Self {
        self.allowed_headers = headers;
        self
    }

    /// Enable credentials
    pub fn allow_credentials(mut self, allow: bool) -> Self {
        self.allow_credentials = allow;
        self
    }
}

impl Middleware for CorsMiddleware {
    fn after_request(
        &self,
        _req: &Request,
        resp: Response,
    ) -> Pin<Box<dyn Future<Output = Response> + Send>> {
        let allowed_origins = self.allowed_origins.join(", ");
        let allowed_methods = self.allowed_methods.join(", ");
        let allowed_headers = self.allowed_headers.join(", ");
        let allow_credentials = self.allow_credentials;
        
        Box::pin(async move {
            let mut resp = resp
                .header("Access-Control-Allow-Origin", allowed_origins)
                .header("Access-Control-Allow-Methods", allowed_methods)
                .header("Access-Control-Allow-Headers", allowed_headers);

            if allow_credentials {
                resp = resp.header("Access-Control-Allow-Credentials", "true");
            }
            
            resp
        })
    }

    fn name(&self) -> &str {
        "CORS"
    }
}

impl Default for CorsMiddleware {
    fn default() -> Self {
        Self::new()
    }
}

/// Logging middleware for request/response logging
pub struct LoggingMiddleware {
    /// Whether to log request bodies
    log_bodies: bool,
    /// Whether to log response bodies
    log_responses: bool,
}

impl LoggingMiddleware {
    /// Create a new logging middleware
    pub fn new() -> Self {
        Self {
            log_bodies: false,
            log_responses: false,
        }
    }

    /// Enable request body logging
    pub fn log_bodies(mut self, enable: bool) -> Self {
        self.log_bodies = enable;
        self
    }

    /// Enable response body logging
    pub fn log_responses(mut self, enable: bool) -> Self {
        self.log_responses = enable;
        self
    }
}

impl Middleware for LoggingMiddleware {
    fn before_request(
        &self,
        req: &mut Request,
    ) -> Pin<Box<dyn Future<Output = Option<Response>> + Send>> {
        let method = req.method().to_string();
        let path = req.path().to_string();
        let remote_ip = req.remote_ip().cloned().unwrap_or_else(|| "unknown".to_string());
        let log_bodies = self.log_bodies;
        let body = req.json().cloned();
        
        Box::pin(async move {
            log::info!("{} {} - {}", method, path, remote_ip);

            if log_bodies {
                if let Some(body) = body {
                    log::debug!("Request body: {}", serde_json::to_string_pretty(&body).unwrap_or_default());
                }
            }

            None
        })
    }

    fn after_request(
        &self,
        req: &Request,
        resp: Response,
    ) -> Pin<Box<dyn Future<Output = Response> + Send>> {
        let method = req.method().to_string();
        let path = req.path().to_string();
        let log_responses = self.log_responses;
        
        Box::pin(async move {
            log::info!("Response for {} {} - Status: {}", method, path, "200"); // TODO: Get actual status from response

            if log_responses {
                log::debug!("Response sent for {} {}", method, path);
            }
            
            resp
        })
    }

    fn name(&self) -> &str {
        "Logging"
    }
}

impl Default for LoggingMiddleware {
    fn default() -> Self {
        Self::new()
    }
}

/// Authentication middleware
pub struct AuthMiddleware {
    /// Paths that don't require authentication
    public_paths: Vec<String>,
    /// JWT secret key
    secret_key: String,
}

impl AuthMiddleware {
    /// Create a new auth middleware
    pub fn new<S: Into<String>>(secret_key: S) -> Self {
        Self {
            public_paths: vec!["/health".to_string(), "/".to_string()],
            secret_key: secret_key.into(),
        }
    }

    /// Add public paths that don't require authentication
    pub fn public_paths(mut self, paths: Vec<String>) -> Self {
        self.public_paths = paths;
        self
    }

    /// Check if path is public
    fn is_public_path(&self, path: &str) -> bool {
        self.public_paths.iter().any(|p| path.starts_with(p))
    }
}

impl Middleware for AuthMiddleware {
    fn before_request(
        &self,
        req: &mut Request,
    ) -> Pin<Box<dyn Future<Output = Option<Response>> + Send>> {
        let path = req.path().to_string();
        let is_public = self.is_public_path(&path);
        let auth_header = req.header("authorization").cloned();
        
        Box::pin(async move {
            if is_public {
                return None;
            }

            // Check for Authorization header
            if let Some(auth_header) = auth_header {
                if auth_header.starts_with("Bearer ") {
                    // TODO: Validate JWT token
                    log::debug!("JWT token validation (not implemented)");
                    return None;
                }
            }

            // Return unauthorized response
            Some(Response::unauthorized("Authentication required"))
        })
    }

    fn name(&self) -> &str {
        "Authentication"
    }
}