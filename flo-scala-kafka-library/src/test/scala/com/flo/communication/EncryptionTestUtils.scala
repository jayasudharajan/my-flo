package com.flo.communication

trait EncryptionTestUtils {
  def encrypt(message: String): String = {
    message.map(x => (x + 10).asInstanceOf[Char])
  }

  def decrypt(message: String): String = {
    message.map(x => (x - 10).asInstanceOf[Char])
  }
}
