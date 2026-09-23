package com.elamine.erp

import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import java.util.concurrent.Executors
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "com.elamine.erp/bluetooth"
    private val serialUuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private var socket: BluetoothSocket? = null

    private val adapter
        get() = (getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "isEnabled" -> result.success(adapter?.isEnabled == true)
                        "pairedDevices" -> {
                            val devices = adapter?.bondedDevices.orEmpty().map {
                                mapOf("name" to (it.name ?: "Inconnu"), "address" to it.address)
                            }
                            result.success(devices)
                        }
                        "connect" -> {
                            val address = call.argument<String>("address")
                            if (address.isNullOrBlank()) {
                                result.error("invalid_address", "Adresse Bluetooth manquante.", null)
                            } else {
                                ioExecutor.execute {
                                    try {
                                        socket?.close()
                                        adapter?.cancelDiscovery()
                                        val candidate = adapter
                                            ?.getRemoteDevice(address)
                                            ?.createRfcommSocketToServiceRecord(serialUuid)
                                            ?: error("Bluetooth indisponible")
                                        candidate.connect()
                                        socket = candidate
                                        runOnUiThread { result.success(true) }
                                    } catch (error: Exception) {
                                        runOnUiThread {
                                            result.error("connection_failure", error.message, null)
                                        }
                                    }
                                }
                            }
                        }
                        "write" -> {
                            val bytes = call.argument<ByteArray>("bytes")
                            if (bytes == null) {
                                result.error("invalid_data", "Données d'impression manquantes.", null)
                            } else {
                                ioExecutor.execute {
                                    try {
                                        val current = socket
                                        if (current == null || !current.isConnected) {
                                            error("Imprimante non connectée")
                                        }
                                        current.outputStream.write(bytes)
                                        current.outputStream.flush()
                                        runOnUiThread { result.success(true) }
                                    } catch (error: Exception) {
                                        runOnUiThread {
                                            result.error("write_failure", error.message, null)
                                        }
                                    }
                                }
                            }
                        }
                        "disconnect" -> {
                            ioExecutor.execute {
                                try {
                                    socket?.close()
                                } finally {
                                    socket = null
                                    runOnUiThread { result.success(null) }
                                }
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: SecurityException) {
                    result.error("permission_denied", error.message, null)
                } catch (error: Exception) {
                    result.error("bluetooth_error", error.message, null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.elamine.erp/files")
            .setMethodCallHandler { call, result ->
                if (call.method != "openPdf") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val path = call.argument<String>("path") ?: error("Chemin PDF manquant")
                    val uri = FileProvider.getUriForFile(
                        this,
                        "$packageName.fileprovider",
                        File(path),
                    )
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/pdf")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    startActivity(intent)
                    result.success(null)
                } catch (error: Exception) {
                    result.error("open_pdf_failed", error.message, null)
                }
            }
    }

    override fun onDestroy() {
        try {
            socket?.close()
        } finally {
            ioExecutor.shutdownNow()
            super.onDestroy()
        }
    }
}
