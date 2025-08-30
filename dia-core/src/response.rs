//! Response module for dia framework
//! 
//! Provides the Response struct for building HTTP responses.

use actix_web::{HttpResponse, http::StatusCode};
use serde::{Serialize};
use serde_json::Value;
use std::collections::HashMap;

/// HTTP response builder that provides a simplified interface
pub struct Response {
    /// HTTP status code
    status: StatusCode,
    /// Response headers
    headers: HashMap<String, String>,
    /// Response body
    body: ResponseBody,
}

/// Enum representing different types of response bodies
#[derive(Debug, Clone)]
pub enum ResponseBody {
    /// Plain text response
    Text(String),
    /// JSON response
    Json(Value),
    /// Binary response
    Binary(Vec<u8>),
    /// Empty response
    Empty,
}

impl Response {
    /// Create a new Response with 200 OK status
    pub fn new() -> Self {
        Self {
            status: StatusCode::OK,
            headers: HashMap::new(),
            body: ResponseBody::Empty,
        }
    }

    /// Set the HTTP status code
    pub fn status(mut self, status: u16) -> Self {
        if let Ok(status_code) = StatusCode::from_u16(status) {
            self.status = status_code;
        }
        self
    }

    /// Set a header
    pub fn header<K: Into<String>, V: Into<String>>(mut self, key: K, value: V) -> Self {
        self.headers.insert(key.into(), value.into());
        self
    }

    /// Set multiple headers
    pub fn headers(mut self, headers: HashMap<String, String>) -> Self {
        self.headers.extend(headers);
        self
    }

    /// Set the response body as plain text
    /// 
    /// # Examples
    /// 
    /// ```rust
    /// use dia_core::Response;
    /// 
    /// let response = Response::new().text("Hello, World!");
    /// ```
    pub fn text<S: Into<String>>(mut self, text: S) -> Self {
        self.body = ResponseBody::Text(text.into());
        self.headers.insert("content-type".to_string(), "text/plain; charset=utf-8".to_string());
        self
    }

    /// Set the response body as JSON
    /// 
    /// # Examples
    /// 
    /// ```rust
    /// use dia_core::Response;
    /// use serde_json::json;
    /// 
    /// let response = Response::new().json(json!({"message": "Hello, World!"}));
    /// ```
    pub fn json<T: Serialize>(mut self, data: T) -> Self {
        match serde_json::to_value(data) {
            Ok(value) => {
                self.body = ResponseBody::Json(value);
                self.headers.insert("content-type".to_string(), "application/json".to_string());
            }
            Err(_) => {
                // Fallback to error response
                self.status = StatusCode::INTERNAL_SERVER_ERROR;
                self.body = ResponseBody::Text("Failed to serialize JSON".to_string());
                self.headers.insert("content-type".to_string(), "text/plain; charset=utf-8".to_string());
            }
        }
        self
    }

    /// Set the response body as HTML
    pub fn html<S: Into<String>>(mut self, html: S) -> Self {
        self.body = ResponseBody::Text(html.into());
        self.headers.insert("content-type".to_string(), "text/html; charset=utf-8".to_string());
        self
    }

    /// Set the response body as binary data
    pub fn binary(mut self, data: Vec<u8>) -> Self {
        self.body = ResponseBody::Binary(data);
        self.headers.insert("content-type".to_string(), "application/octet-stream".to_string());
        self
    }

    /// Create a redirect response
    pub fn redirect<S: Into<String>>(mut self, url: S) -> Self {
        self.status = StatusCode::FOUND;
        self.headers.insert("location".to_string(), url.into());
        self
    }

    /// Create a not found response
    pub fn not_found() -> Self {
        Self::new()
            .status(404)
            .text("Not Found")
    }

    /// Create an internal server error response
    pub fn internal_error() -> Self {
        Self::new()
            .status(500)
            .text("Internal Server Error")
    }

    /// Convert to actix-web HttpResponse
    pub fn into_http_response(self) -> HttpResponse {
        let mut builder = HttpResponse::build(self.status);

        // Add headers
        for (key, value) in self.headers {
            builder.insert_header((key, value));
        }

        // Add body
        match self.body {
            ResponseBody::Text(text) => builder.body(text),
            ResponseBody::Json(json) => builder.json(json),
            ResponseBody::Binary(data) => builder.body(data),
            ResponseBody::Empty => builder.finish(),
        }
    }
}

impl Default for Response {
    fn default() -> Self {
        Self::new()
    }
}

// Convenience functions for common responses
impl Response {
    /// Create a 200 OK response with text
    pub fn ok_text<S: Into<String>>(text: S) -> Self {
        Self::new().text(text)
    }

    /// Create a 200 OK response with JSON
    pub fn ok_json<T: Serialize>(data: T) -> Self {
        Self::new().json(data)
    }

    /// Create a 400 Bad Request response
    pub fn bad_request<S: Into<String>>(message: S) -> Self {
        Self::new().status(400).text(message)
    }

    /// Create a 401 Unauthorized response
    pub fn unauthorized<S: Into<String>>(message: S) -> Self {
        Self::new().status(401).text(message)
    }

    /// Create a 403 Forbidden response
    pub fn forbidden<S: Into<String>>(message: S) -> Self {
        Self::new().status(403).text(message)
    }
}