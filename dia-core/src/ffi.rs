//! FFI module for dia framework
//! 
//! Provides C-compatible interfaces for Zig integration.

use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::ptr;
use crate::{Application, Response};

/// Opaque pointer to Application instance
#[repr(C)]
pub struct DiaApplication {
    _private: [u8; 0],
}

/// Opaque pointer to Response instance  
#[repr(C)]
pub struct DiaResponse {
    _private: [u8; 0],
}

/// Create a new dia application
#[unsafe(no_mangle)]
pub extern "C" fn dia_application_new() -> *mut DiaApplication {
    let app = Box::new(Application::new());
    Box::into_raw(app) as *mut DiaApplication
}

/// Set the host for the application
#[unsafe(no_mangle)]
pub extern "C" fn dia_application_host(
    app: *mut DiaApplication, 
    host: *const c_char
) -> c_int {
    if app.is_null() || host.is_null() {
        return -1;
    }

    unsafe {
        let _app = app as *mut Application;
        let _host_str = match CStr::from_ptr(host).to_str() {
            Ok(s) => s,
            Err(_) => return -1,
        };

        // TODO: Implement proper host setting
        // This is a limitation of the current design
    }

    0
}

/// Set the port for the application
#[unsafe(no_mangle)]
pub extern "C" fn dia_application_port(
    app: *mut DiaApplication,
    port: u16
) -> c_int {
    if app.is_null() {
        return -1;
    }

    unsafe {
        let _app = app as *mut Application;
        // TODO: Implement proper port setting
        // This is a limitation of the current design
    }

    0
}

/// Run the application (blocking)
#[unsafe(no_mangle)]
pub extern "C" fn dia_application_run(app: *mut DiaApplication) -> c_int {
    if app.is_null() {
        return -1;
    }

    unsafe {
        let app = Box::from_raw(app as *mut Application);
        
        // Create a simple runtime for the blocking call
        let rt = match tokio::runtime::Runtime::new() {
            Ok(rt) => rt,
            Err(_) => return -1,
        };

        match rt.block_on(app.run()) {
            Ok(_) => 0,
            Err(_) => -1,
        }
    }
}

/// Free the application
#[unsafe(no_mangle)]
pub extern "C" fn dia_application_free(app: *mut DiaApplication) {
    if !app.is_null() {
        unsafe {
            drop(Box::from_raw(app as *mut Application));
        }
    }
}

/// Create a new response
#[unsafe(no_mangle)]
pub extern "C" fn dia_response_new() -> *mut DiaResponse {
    let response = Box::new(Response::new());
    Box::into_raw(response) as *mut DiaResponse
}

/// Set response text
#[unsafe(no_mangle)]
pub extern "C" fn dia_response_text(
    resp: *mut DiaResponse,
    text: *const c_char
) -> c_int {
    if resp.is_null() || text.is_null() {
        return -1;
    }

    unsafe {
        let _response = resp as *mut Response;
        let _text_str = match CStr::from_ptr(text).to_str() {
            Ok(s) => s,
            Err(_) => return -1,
        };

        // TODO: Implement proper response text setting
        // This is a limitation of the current design
    }

    0
}

/// Set response JSON from string
#[unsafe(no_mangle)]
pub extern "C" fn dia_response_json(
    resp: *mut DiaResponse,
    json_str: *const c_char
) -> c_int {
    if resp.is_null() || json_str.is_null() {
        return -1;
    }

    unsafe {
        let _response = resp as *mut Response;
        let _json_str = match CStr::from_ptr(json_str).to_str() {
            Ok(s) => s,
            Err(_) => return -1,
        };

        // TODO: Implement proper JSON response setting
        // This is a limitation of the current design
    }

    0
}

/// Set response status
#[unsafe(no_mangle)]
pub extern "C" fn dia_response_status(
    resp: *mut DiaResponse,
    status: u16
) -> c_int {
    if resp.is_null() {
        return -1;
    }

    unsafe {
        let _response = resp as *mut Response;
        
        // TODO: Implement proper status setting
        // This is a limitation of the current design
    }

    0
}

/// Free the response
#[unsafe(no_mangle)]
pub extern "C" fn dia_response_free(resp: *mut DiaResponse) {
    if !resp.is_null() {
        unsafe {
            drop(Box::from_raw(resp as *mut Response));
        }
    }
}

/// Simple handler function type for FFI
pub type DiaHandlerFn = extern "C" fn() -> *mut DiaResponse;

/// Register a simple GET route
#[unsafe(no_mangle)]
pub extern "C" fn dia_application_get(
    app: *mut DiaApplication,
    path: *const c_char,
    _handler: DiaHandlerFn
) -> c_int {
    if app.is_null() || path.is_null() {
        return -1;
    }

    // TODO: Implement route registration
    // This requires a more complex design to handle the conversion
    // between C function pointers and Rust async functions
    
    0
}