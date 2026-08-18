//! Rust Security Layer for My-Money Application
//! 
//! This module provides cryptographic utilities and security functions
//! for the Flutter/Dart application through FFI.

use ffi_support::{define_string_function, ByteBuffer};
use zeroize::Zeroize;
use rand::RngCore;
use rand_chacha::ChaCha20Rng;
use rand::SeedableRng;
use sha2::{Sha256, Digest};
use hmac::{Hmac, Mac};
use argon2::Argon2;
use aes_gcm::{Aes256Gcm, Key, Nonce};
use aes_gcm::aead::{Aead, KeyInit};
use serde::{Serialize, Deserialize};
use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};

type HmacSha256 = Hmac<Sha256>;

// ============================================================================
// Data Structures
// ============================================================================

#[derive(Serialize, Deserialize, Zeroize)]
pub struct SecureBuffer {
    #[zeroize(skip)]
    pub data: Vec<u8>,
}

impl SecureBuffer {
    pub fn new(data: Vec<u8>) -> Self {
        Self { data }
    }

    pub fn into_bytes(self) -> Vec<u8> {
        self.data
    }
}

#[derive(Serialize, Deserialize)]
pub struct EncryptionResult {
    pub ciphertext: String,
    pub nonce: String,
    pub tag: String,
}

#[derive(Serialize, Deserialize)]
pub struct DecryptionResult {
    pub plaintext: Vec<u8>,
    pub success: bool,
    pub error: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct HashResult {
    pub hash: String,
    pub algorithm: String,
}

#[derive(Serialize, Deserialize)]
pub struct KeyDerivationResult {
    pub derived_key: String,
    pub salt: String,
    pub algorithm: String,
}

#[derive(Serialize, Deserialize)]
pub struct SecureRandomResult {
    pub bytes: Vec<u8>,
    pub hex: String,
    pub base64: String,
}

// ============================================================================
// Secure Random Generation
// ============================================================================

/// Generate cryptographically secure random bytes
pub fn generate_secure_random(length: usize) -> SecureRandomResult {
    let mut rng = ChaCha20Rng::from_entropy();
    let mut bytes = vec![0u8; length];
    rng.fill_bytes(&mut bytes);
    
    let hex = hex::encode(&bytes);
    let base64 = BASE64.encode(&bytes);
    
    SecureRandomResult { bytes, hex, base64 }
}

/// Generate a secure random UUID v4
pub fn generate_uuid() -> String {
    let mut rng = ChaCha20Rng::from_entropy();
    let mut bytes = [0u8; 16];
    rng.fill_bytes(&mut bytes);
    
    // Set version (4) and variant bits
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    
    format!(
        "{:02x}{:02x}{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}{:02x}{:02x}{:02x}{:02x}",
        bytes[0], bytes[1], bytes[2], bytes[3],
        bytes[4], bytes[5], bytes[6], bytes[7],
        bytes[8], bytes[9], bytes[10], bytes[11],
        bytes[12], bytes[13], bytes[14], bytes[15]
    )
}

// ============================================================================
// Hashing Functions
// ============================================================================

/// Compute SHA-256 hash of input data
pub fn sha256_hash(data: &[u8]) -> HashResult {
    let mut hasher = Sha256::new();
    hasher.update(data);
    let result = hasher.finalize();
    
    HashResult {
        hash: hex::encode(result),
        algorithm: "SHA-256".to_string(),
    }
}

/// Compute HMAC-SHA256
pub fn hmac_sha256(key: &[u8], data: &[u8]) -> HashResult {
    let mut mac = HmacSha256::new_from_slice(key)
        .expect("HMAC can take key of any size");
    mac.update(data);
    let result = mac.finalize().into_bytes();
    
    HashResult {
        hash: hex::encode(result),
        algorithm: "HMAC-SHA256".to_string(),
    }
}

// ============================================================================
// Password Hashing (Argon2)
// ============================================================================

/// Hash a password using Argon2id
pub fn hash_password(password: &str, salt: &[u8]) -> KeyDerivationResult {
    let argon2 = Argon2::default();
    let hash = argon2.hash_password(password.as_bytes(), salt)
        .expect("Failed to hash password")
        .to_string();
    
    KeyDerivationResult {
        derived_key: hash,
        salt: hex::encode(salt),
        algorithm: "Argon2id".to_string(),
    }
}

/// Verify a password against an Argon2 hash
pub fn verify_password(password: &str, hash: &str) -> bool {
    let parsed_hash = argon2::PasswordHash::new(hash)
        .expect("Invalid password hash format");
    
    Argon2::default()
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok()
}

// ============================================================================
// Encryption/Decryption (AES-256-GCM)
// ============================================================================

/// Encrypt data using AES-256-GCM
pub fn encrypt_aes_gcm(plaintext: &[u8], key: &[u8]) -> Result<EncryptionResult, String> {
    if key.len() != 32 {
        return Err("Key must be 32 bytes for AES-256".to_string());
    }
    
    // Generate random nonce
    let mut rng = ChaCha20Rng::from_entropy();
    let mut nonce_bytes = [0u8; 12];
    rng.fill_bytes(&mut nonce_bytes);
    
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
    let nonce = Nonce::from_slice(&nonce_bytes);
    
    let ciphertext = cipher.encrypt(nonce, plaintext)
        .map_err(|e| format!("Encryption failed: {}", e))?;
    
    Ok(EncryptionResult {
        ciphertext: BASE64.encode(&ciphertext),
        nonce: BASE64.encode(&nonce_bytes),
        tag: String::new(), // Tag is included in ciphertext for aes-gcm
    })
}

/// Decrypt data using AES-256-GCM
pub fn decrypt_aes_gcm(ciphertext_b64: &str, key: &[u8], nonce_b64: &str) -> DecryptionResult {
    if key.len() != 32 {
        return DecryptionResult {
            plaintext: vec![],
            success: false,
            error: Some("Key must be 32 bytes for AES-256".to_string()),
        };
    }
    
    let ciphertext = match BASE64.decode(ciphertext_b64) {
        Ok(data) => data,
        Err(e) => return DecryptionResult {
            plaintext: vec![],
            success: false,
            error: Some(format!("Failed to decode ciphertext: {}", e)),
        },
    };
    
    let nonce_bytes = match BASE64.decode(nonce_b64) {
        Ok(data) => data,
        Err(e) => return DecryptionResult {
            plaintext: vec![],
            success: false,
            error: Some(format!("Failed to decode nonce: {}", e)),
        },
    };
    
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
    let nonce = Nonce::from_slice(&nonce_bytes);
    
    match cipher.decrypt(nonce, ciphertext.as_slice()) {
        Ok(plaintext) => DecryptionResult {
            plaintext,
            success: true,
            error: None,
        },
        Err(e) => DecryptionResult {
            plaintext: vec![],
            success: false,
            error: Some(format!("Decryption failed: {}", e)),
        },
    }
}

// ============================================================================
// Key Derivation
// ============================================================================

/// Derive a key from a password using Argon2
pub fn derive_key(password: &str, salt: &[u8], output_length: usize) -> KeyDerivationResult {
    let argon2 = Argon2::default();
    let mut output = vec![0u8; output_length];
    
    argon2.hash_password_into(password.as_bytes(), salt, &mut output)
        .expect("Failed to derive key");
    
    KeyDerivationResult {
        derived_key: BASE64.encode(&output),
        salt: hex::encode(salt),
        algorithm: "Argon2id".to_string(),
    }
}

// ============================================================================
// FFI Functions for Flutter Integration
// ============================================================================

define_string_function!(generate_uuid_ffi {
    generate_uuid()
});

define_string_function!(generate_secure_random_hex_ffi {
    let result = generate_secure_random(32);
    result.hex
});

define_string_function!(sha256_hash_ffi {
    let result = sha256_hash(data.as_bytes());
    result.hash
});

define_string_function!(hmac_sha256_ffi {
    // Expected format: "key|data"
    let parts: Vec<&str> = input.splitn(2, '|').collect();
    if parts.len() != 2 {
        return "ERROR: Invalid input format".to_string();
    }
    let result = hmac_sha256(parts[0].as_bytes(), parts[1].as_bytes());
    result.hash
});

#[no_mangle]
pub extern "C" fn encrypt_data_ffi(plaintext_ptr: *const u8, plaintext_len: i32, 
                                    key_ptr: *const u8, key_len: i32) -> ByteBuffer {
    let plaintext = unsafe {
        std::slice::from_raw_parts(plaintext_ptr, plaintext_len as usize)
    };
    let key = unsafe {
        std::slice::from_raw_parts(key_ptr, key_len as usize)
    };
    
    match encrypt_aes_gcm(plaintext, key) {
        Ok(result) => {
            let json = serde_json::to_string(&result).unwrap_or_default();
            ByteBuffer::from_vec(json.into_bytes())
        }
        Err(e) => {
            let error_result = serde_json::json!({ "error": e });
            ByteBuffer::from_vec(error_result.to_string().into_bytes())
        }
    }
}

#[no_mangle]
pub extern "C" fn decrypt_data_ffi(ciphertext_ptr: *const u8, ciphertext_len: i32,
                                    key_ptr: *const u8, key_len: i32,
                                    nonce_ptr: *const u8, nonce_len: i32) -> ByteBuffer {
    let ciphertext = unsafe {
        std::slice::from_raw_parts(ciphertext_ptr, ciphertext_len as usize)
    };
    let key = unsafe {
        std::slice::from_raw_parts(key_ptr, key_len as usize)
    };
    let nonce = unsafe {
        std::slice::from_raw_parts(nonce_ptr, nonce_len as usize)
    };
    
    let ciphertext_b64 = BASE64.encode(ciphertext);
    let nonce_b64 = BASE64.encode(nonce);
    
    let result = decrypt_aes_gcm(&ciphertext_b64, key, &nonce_b64);
    let json = serde_json::to_string(&result).unwrap_or_default();
    ByteBuffer::from_vec(json.into_bytes())
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_uuid() {
        let uuid1 = generate_uuid();
        let uuid2 = generate_uuid();
        assert_ne!(uuid1, uuid2);
        assert_eq!(uuid1.len(), 36);
    }

    #[test]
    fn test_sha256_hash() {
        let result = sha256_hash(b"test data");
        assert_eq!(result.algorithm, "SHA-256");
        assert_eq!(result.hash.len(), 64); // 256 bits = 64 hex chars
    }

    #[test]
    fn test_hmac_sha256() {
        let result = hmac_sha256(b"secret key", b"message");
        assert_eq!(result.algorithm, "HMAC-SHA256");
        assert_eq!(result.hash.len(), 64);
    }

    #[test]
    fn test_encrypt_decrypt_roundtrip() {
        let mut rng = ChaCha20Rng::from_entropy();
        let mut key = [0u8; 32];
        rng.fill_bytes(&mut key);
        
        let plaintext = b"Secret message to encrypt";
        let encrypted = encrypt_aes_gcm(plaintext, &key).unwrap();
        
        let ciphertext = BASE64.decode(&encrypted.ciphertext).unwrap();
        let nonce = BASE64.decode(&encrypted.nonce).unwrap();
        
        let decrypted = decrypt_aes_gcm(&encrypted.ciphertext, &key, &encrypted.nonce);
        
        assert!(decrypted.success);
        assert_eq!(decrypted.plaintext, plaintext.to_vec());
    }

    #[test]
    fn test_secure_random() {
        let result1 = generate_secure_random(32);
        let result2 = generate_secure_random(32);
        
        assert_ne!(result1.bytes, result2.bytes);
        assert_eq!(result1.bytes.len(), 32);
        assert_eq!(result1.hex.len(), 64);
    }
}
