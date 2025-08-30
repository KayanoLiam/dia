//! Request module for dia framework
//! 
//! Provides the Request struct for handling HTTP requests.

use serde_json::Value;
use std::collections::HashMap;

/// HTTP request wrapper that provides a simplified interface
#[derive(Debug, Clone)]
pub struct Request {
    /// HTTP method
    method: String,
    /// Request path
    path: String,
    /// Request headers
    headers: HashMap<String, String>,
    /// Request body as JSON value
    body: Option<Value>,
    /// Path parameters
    path_params: HashMap<String, String>,
    /// Query parameters  
    query_params: HashMap<String, String>,
    /// Remote IP address
    remote_ip: Option<String>,
}

impl Request {
    /// Create a new Request from actix-web HttpRequest
    pub fn new(req: actix_web::HttpRequest) -> Self {
        let query_params = req
            .query_string()
            .split('&')
            .filter_map(|param| {
                let mut parts = param.splitn(2, '=');
                match (parts.next(), parts.next()) {
                    (Some(key), Some(value)) => Some((
                        urlencoding::decode(key).unwrap_or_default().to_string(),
                        urlencoding::decode(value).unwrap_or_default().to_string(),
                    )),
                    _ => None,
                }
            })
            .collect();

        let headers = req
            .headers()
            .iter()
            .filter_map(|(name, value)| {
                value.to_str().ok().map(|v| (name.to_string(), v.to_string()))
            })
            .collect();

        let remote_ip = req
            .connection_info()
            .realip_remote_addr()
            .map(|ip| ip.to_string());

        Self {
            method: req.method().to_string(),
            path: req.path().to_string(),
            headers,
            body: None,
            path_params: HashMap::new(),
            query_params,
            remote_ip,
        }
    }

    /// Get the HTTP method
    pub fn method(&self) -> &str {
        &self.method
    }

    /// Get the request path
    pub fn path(&self) -> &str {
        &self.path
    }

    /// Get a header value by name
    pub fn header(&self, name: &str) -> Option<&String> {
        self.headers.get(name)
    }

    /// Get all headers as a HashMap
    pub fn headers(&self) -> &HashMap<String, String> {
        &self.headers
    }

    /// Get a query parameter by name
    pub fn query(&self, name: &str) -> Option<&String> {
        self.query_params.get(name)
    }

    /// Get all query parameters
    pub fn query_params(&self) -> &HashMap<String, String> {
        &self.query_params
    }

    /// Get a path parameter by name
    pub fn param(&self, name: &str) -> Option<&String> {
        self.path_params.get(name)
    }

    /// Set path parameters (used internally by routing)
    pub fn set_path_params(&mut self, params: HashMap<String, String>) {
        self.path_params = params;
    }

    /// Get the request body as JSON
    pub fn json(&self) -> Option<&Value> {
        self.body.as_ref()
    }

    /// Set the request body (used internally)
    pub fn set_body(&mut self, body: Value) {
        self.body = Some(body);
    }

    /// Get the content type
    pub fn content_type(&self) -> Option<&str> {
        self.header("content-type").map(|s| s.as_str())
    }

    /// Check if the request is JSON
    pub fn is_json(&self) -> bool {
        self.header("content-type")
            .map(|ct| ct.contains("application/json"))
            .unwrap_or(false)
    }

    /// Get the remote IP address
    pub fn remote_ip(&self) -> Option<&String> {
        self.remote_ip.as_ref()
    }

    /// Get the user agent
    pub fn user_agent(&self) -> Option<&String> {
        self.header("user-agent")
    }
}