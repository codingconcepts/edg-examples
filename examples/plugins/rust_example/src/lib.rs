use serde::Serialize;
use std::cell::RefCell;

thread_local! {
    static ALLOC_BUF: RefCell<Vec<u8>> = RefCell::new(Vec::new());
}

#[no_mangle]
pub extern "C" fn alloc(size: i32) -> i32 {
    ALLOC_BUF.with(|buf| {
        let mut buf = buf.borrow_mut();
        buf.resize(size as usize, 0);
        buf.as_ptr() as i32
    })
}

#[derive(Serialize)]
struct Manifest {
    name: &'static str,
    functions: &'static [FuncDesc],
}

#[derive(Serialize)]
struct FuncDesc {
    name: &'static str,
    description: &'static str,
    example: &'static str,
    params: &'static [ParamDesc],
    returns: &'static str,
}

#[derive(Serialize)]
struct ParamDesc {
    name: &'static str,
    r#type: &'static str,
}

static MANIFEST: Manifest = Manifest {
    name: "rust_example",
    functions: &[
        FuncDesc {
            name: "card_mask",
            description: "Mask all but the last N characters of a string.",
            example: "card_mask('4111111111111111', 4)",
            params: &[
                ParamDesc {
                    name: "string",
                    r#type: "string",
                },
                ParamDesc {
                    name: "int",
                    r#type: "int",
                },
            ],
            returns: "string",
        },
        FuncDesc {
            name: "initials",
            description: "Extract uppercase initials from a full name.",
            example: "initials('Jane Doe')",
            params: &[ParamDesc {
                name: "string",
                r#type: "string",
            }],
            returns: "string",
        },
    ],
};

fn write_to_memory(data: &[u8]) -> i64 {
    let ptr = alloc(data.len() as i32);
    unsafe {
        std::ptr::copy_nonoverlapping(data.as_ptr(), ptr as *mut u8, data.len());
    }
    ((ptr as i64) << 32) | (data.len() as i64)
}

fn write_error(msg: &str) -> i64 {
    let data = format!(r#"{{"error":"{}"}}"#, msg);
    write_to_memory(data.as_bytes())
}

#[no_mangle]
pub extern "C" fn describe() -> i64 {
    let data = serde_json::to_vec(&MANIFEST).unwrap();
    write_to_memory(&data)
}

#[no_mangle]
pub extern "C" fn call(fn_id: i32, arg_ptr: i32, arg_len: i32) -> i64 {
    let arg_data = unsafe { std::slice::from_raw_parts(arg_ptr as *const u8, arg_len as usize) };

    let args: Vec<serde_json::Value> = match serde_json::from_slice(arg_data) {
        Ok(v) => v,
        Err(e) => return write_error(&format!("unmarshal args: {e}")),
    };

    match fn_id {
        0 => {
            let input = match args.first().and_then(|v| v.as_str()) {
                Some(s) => s,
                None => return write_error("mask: expected string as first argument"),
            };
            let visible = match args.get(1).and_then(|v| v.as_i64()) {
                Some(n) if n >= 0 => n as usize,
                _ => return write_error("mask: expected non-negative int as second argument"),
            };
            let chars: Vec<char> = input.chars().collect();
            let masked: String = chars
                .iter()
                .enumerate()
                .map(|(i, &c)| {
                    if i < chars.len().saturating_sub(visible) {
                        '*'
                    } else {
                        c
                    }
                })
                .collect();
            let data = serde_json::to_vec(&masked).unwrap();
            write_to_memory(&data)
        }
        1 => {
            let name = match args.first().and_then(|v| v.as_str()) {
                Some(s) => s,
                None => return write_error("initials: expected string argument"),
            };
            let result: String = name
                .split_whitespace()
                .filter_map(|w| w.chars().next())
                .map(|c| c.to_uppercase().next().unwrap_or(c))
                .collect();
            let data = serde_json::to_vec(&result).unwrap();
            write_to_memory(&data)
        }
        _ => write_error("invalid function ID"),
    }
}
