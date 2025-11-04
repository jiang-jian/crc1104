package com.holox.ailand_pos

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * 外接USB读卡器插件
 * 用于检测和管理通过USB连接的外接读卡器设备
 * 支持各类IC卡读卡器（ISO 14443 Type A/B, Mifare等）
 */
class ExternalCardReaderPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var usbManager: UsbManager? = null
    private var currentConnection: UsbDeviceConnection? = null
    private val cardReadExecutor = Executors.newSingleThreadScheduledExecutor()

    companion object {
        private const val TAG = "ExternalCardReader"
        private const val CHANNEL_NAME = "com.holox.ailand_pos/external_card_reader"
        private const val ACTION_USB_PERMISSION = "com.holox.ailand_pos.USB_CARD_READER_PERMISSION"
        
        // USB设备类代码
        private const val USB_CLASS_SMART_CARD = 11  // CCID (Chip Card Interface Device)
        private const val USB_CLASS_VENDOR_SPECIFIC = 0xFF  // 厂商自定义类
        
        // 常见读卡器厂商ID（可根据实际使用的设备扩展）
        private val KNOWN_CARD_READER_VENDORS = listOf(
            0x072f,  // Advanced Card Systems (ACS)
            0x04e6,  // SCM Microsystems
            0x0b97,  // O2 Micro
            0x076b,  // OmniKey (HID Global)
            0x08e6,  // Gemalto (现Thales)
            0x0403,  // FTDI (常用于串口读卡器)
            0x1a86,  // QinHeng (常见中国制造商)
            0x0483,  // STMicroelectronics
            0x1fc9,  // NXP Semiconductors
        )
    }

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                ACTION_USB_PERMISSION -> {
                    synchronized(this) {
                        val device: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                        }

                        if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                            device?.let {
                                Log.d(TAG, "USB permission granted for card reader: ${it.deviceName}")
                                channel.invokeMethod("onPermissionGranted", mapOf("deviceId" to it.deviceId.toString()))
                            }
                        } else {
                            Log.d(TAG, "USB permission denied for device: ${device?.deviceName}")
                            channel.invokeMethod("onPermissionDenied", null)
                        }
                    }
                }
                UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                    val device: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    }
                    
                    if (device != null && isCardReaderDevice(device)) {
                        Log.d(TAG, "Card reader device attached: ${device.deviceName}")
                        channel.invokeMethod("onUsbDeviceAttached", null)
                    }
                }
                UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                    val device: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    }
                    
                    if (device != null && isCardReaderDevice(device)) {
                        Log.d(TAG, "Card reader device detached: ${device.deviceName}")
                        closeConnection()
                        channel.invokeMethod("onUsbDeviceDetached", null)
                    }
                }
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        usbManager = context?.getSystemService(Context.USB_SERVICE) as? UsbManager

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        // 注册USB设备广播接收器
        val filter = IntentFilter().apply {
            addAction(ACTION_USB_PERMISSION)
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context?.registerReceiver(usbReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context?.registerReceiver(usbReceiver, filter)
        }

        Log.d(TAG, "ExternalCardReaderPlugin attached")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        try {
            context?.unregisterReceiver(usbReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver: ${e.message}")
        }
        closeConnection()
        cardReadExecutor.shutdown()
        context = null
        usbManager = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "scanUsbReaders" -> scanUsbReaders(result)
            "requestPermission" -> requestPermission(call, result)
            "readCard" -> readCard(call, result)
            else -> result.notImplemented()
        }
    }

    /**
     * 扫描USB读卡器设备
     */
    private fun scanUsbReaders(result: Result) {
        try {
            val deviceList = usbManager?.deviceList ?: emptyMap()
            Log.d(TAG, "Scanning USB devices, found: ${deviceList.size}")

            val cardReaders = deviceList.values
                .filter { isCardReaderDevice(it) }
                .map { device ->
                    val deviceInfo = getDeviceInfo(device)
                    hashMapOf(
                        "deviceId" to device.deviceId.toString(),
                        "deviceName" to device.deviceName,
                        "manufacturer" to (device.manufacturerName ?: "Unknown"),
                        "productName" to (device.productName ?: "Unknown"),
                        "model" to deviceInfo["model"],
                        "specifications" to deviceInfo["specifications"],
                        "vendorId" to device.vendorId,
                        "productId" to device.productId,
                        "isConnected" to (usbManager?.hasPermission(device) == true),
                        "serialNumber" to device.serialNumber
                    )
                }

            Log.d(TAG, "Found ${cardReaders.size} card reader devices")
            result.success(cardReaders)
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning USB devices: ${e.message}", e)
            result.error("SCAN_ERROR", "Failed to scan USB devices: ${e.message}", null)
        }
    }

    /**
     * 判断是否为读卡器设备
     */
    private fun isCardReaderDevice(device: UsbDevice): Boolean {
        // 方法1: 检查USB设备类（CCID - Chip Card Interface Device）
        if (device.deviceClass == USB_CLASS_SMART_CARD) {
            Log.d(TAG, "Device ${device.deviceName} is a card reader (CCID class)")
            return true
        }

        // 方法2: 检查接口类
        for (i in 0 until device.interfaceCount) {
            val usbInterface = device.getInterface(i)
            if (usbInterface.interfaceClass == USB_CLASS_SMART_CARD) {
                Log.d(TAG, "Device ${device.deviceName} is a card reader (CCID interface)")
                return true
            }
        }

        // 方法3: 检查常见读卡器厂商ID
        if (device.vendorId in KNOWN_CARD_READER_VENDORS) {
            Log.d(TAG, "Device ${device.deviceName} is likely a card reader (known vendor: 0x${device.vendorId.toString(16)})")
            return true
        }

        // 方法4: 通过产品名称关键词判断
        val productName = device.productName?.lowercase() ?: ""
        val cardReaderKeywords = listOf("card", "reader", "rfid", "nfc", "smartcard", "ccid", "mifare")
        if (cardReaderKeywords.any { productName.contains(it) }) {
            Log.d(TAG, "Device ${device.deviceName} is likely a card reader (by product name)")
            return true
        }

        return false
    }

    /**
     * 获取设备详细信息
     */
    private fun getDeviceInfo(device: UsbDevice): Map<String, String?> {
        val productName = device.productName ?: "Unknown"
        val manufacturer = device.manufacturerName ?: "Unknown"
        
        // 根据厂商ID推断型号和规格
        val info = when (device.vendorId) {
            0x072f -> mapOf(
                "model" to "ACS ${productName}",
                "specifications" to "ISO 14443 Type A/B, Mifare"
            )
            0x04e6 -> mapOf(
                "model" to "SCM ${productName}",
                "specifications" to "ISO 14443, ISO 7816"
            )
            0x076b -> mapOf(
                "model" to "OmniKey ${productName}",
                "specifications" to "ISO 14443, Mifare, DESFire"
            )
            else -> mapOf(
                "model" to productName,
                "specifications" to "Smart Card Reader"
            )
        }
        
        return info
    }

    /**
     * 请求USB设备权限
     */
    private fun requestPermission(call: MethodCall, result: Result) {
        try {
            val deviceId = call.argument<String>("deviceId")
            if (deviceId == null) {
                result.error("INVALID_ARGUMENT", "Device ID is required", null)
                return
            }

            val device = findDeviceById(deviceId)
            if (device == null) {
                result.error("DEVICE_NOT_FOUND", "Device not found: $deviceId", null)
                return
            }

            if (usbManager?.hasPermission(device) == true) {
                Log.d(TAG, "Already has permission for device: ${device.deviceName}")
                result.success(true)
                return
            }

            val permissionIntent = PendingIntent.getBroadcast(
                context,
                0,
                Intent(ACTION_USB_PERMISSION),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_MUTABLE
                } else {
                    0
                }
            )

            usbManager?.requestPermission(device, permissionIntent)
            Log.d(TAG, "Requesting permission for device: ${device.deviceName}")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting permission: ${e.message}", e)
            result.error("PERMISSION_ERROR", "Failed to request permission: ${e.message}", null)
        }
    }

    /**
     * 读取卡片数据
     */
    private fun readCard(call: MethodCall, result: Result) {
        try {
            val deviceId = call.argument<String>("deviceId")
            if (deviceId == null) {
                result.error("INVALID_ARGUMENT", "Device ID is required", null)
                return
            }

            val device = findDeviceById(deviceId)
            if (device == null) {
                result.error("DEVICE_NOT_FOUND", "Device not found: $deviceId", null)
                return
            }

            if (usbManager?.hasPermission(device) != true) {
                result.error("NO_PERMISSION", "No permission for device", null)
                return
            }

            // 在后台线程执行读卡操作
            cardReadExecutor.submit {
                try {
                    val cardData = performCardRead(device)
                    
                    // 切回主线程返回结果
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        if (cardData != null) {
                            result.success(
                                hashMapOf(
                                    "success" to true,
                                    "message" to "读卡成功",
                                    "cardData" to cardData
                                )
                            )
                        } else {
                            result.success(
                                hashMapOf(
                                    "success" to false,
                                    "message" to "未检测到卡片或读取失败",
                                    "errorCode" to "NO_CARD"
                                )
                            )
                        }
                    }
                } catch (e: Exception) {
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        Log.e(TAG, "Error reading card: ${e.message}", e)
                        result.error("READ_ERROR", "Card read failed: ${e.message}", null)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error during card read: ${e.message}", e)
            result.error("READ_ERROR", "Card read failed: ${e.message}", null)
        }
    }

    /**
     * 执行实际的读卡操作
     * 使用CCID协议与读卡器通信
     */
    private fun performCardRead(device: UsbDevice): Map<String, Any>? {
        var connection: UsbDeviceConnection? = null
        try {
            connection = usbManager?.openDevice(device)
            if (connection == null) {
                Log.e(TAG, "Failed to open device connection")
                return null
            }

            currentConnection = connection

            // 查找CCID接口
            val ccidInterface = findCCIDInterface(device)
            if (ccidInterface == null) {
                Log.e(TAG, "No CCID interface found")
                return null
            }

            connection.claimInterface(ccidInterface, true)

            // 查找端点
            var inEndpoint: UsbEndpoint? = null
            var outEndpoint: UsbEndpoint? = null
            for (i in 0 until ccidInterface.endpointCount) {
                val endpoint = ccidInterface.getEndpoint(i)
                if (endpoint.direction == android.hardware.usb.UsbConstants.USB_DIR_IN) {
                    inEndpoint = endpoint
                } else {
                    outEndpoint = endpoint
                }
            }

            if (inEndpoint == null || outEndpoint == null) {
                Log.e(TAG, "Missing required endpoints")
                return null
            }

            // 1. 发送IccPowerOn命令激活卡片
            val powerOnCommand = buildIccPowerOnCommand()
            val powerOnResponse = sendCommand(connection, outEndpoint, inEndpoint, powerOnCommand)
            
            if (powerOnResponse == null || !isSuccessResponse(powerOnResponse)) {
                Log.e(TAG, "Failed to power on card")
                return null
            }

            // 2. 提取ATR (Answer To Reset)
            val atr = extractATR(powerOnResponse)
            if (atr.isEmpty()) {
                Log.e(TAG, "No ATR received")
                return null
            }

            Log.d(TAG, "ATR received: ${atr.joinToString("") { "%02X".format(it) }}")

            // 3. 发送Get UID命令（ISO 14443-3）
            val getUidCommand = buildGetUidCommand()
            val uidResponse = sendCommand(connection, outEndpoint, inEndpoint, getUidCommand)
            
            val uid = if (uidResponse != null && isSuccessResponse(uidResponse)) {
                extractUid(uidResponse)
            } else {
                // 如果无法获取UID，从ATR中尝试提取
                extractUidFromATR(atr)
            }

            // 4. 识别卡片类型
            val cardType = identifyCardType(atr)

            // 5. 构建返回数据
            return hashMapOf(
                "uid" to formatUid(uid),
                "type" to cardType,
                "capacity" to getCardCapacity(cardType),
                "timestamp" to java.time.Instant.now().toString(),
                "isValid" to true,
                "atr" to atr.joinToString("") { "%02X".format(it) }
            )
        } catch (e: IOException) {
            Log.e(TAG, "IO Error during card read: ${e.message}", e)
            return null
        } catch (e: Exception) {
            Log.e(TAG, "Error during card read: ${e.message}", e)
            return null
        } finally {
            connection?.close()
            currentConnection = null
        }
    }

    /**
     * 查找CCID接口
     */
    private fun findCCIDInterface(device: UsbDevice): android.hardware.usb.UsbInterface? {
        for (i in 0 until device.interfaceCount) {
            val usbInterface = device.getInterface(i)
            if (usbInterface.interfaceClass == USB_CLASS_SMART_CARD) {
                return usbInterface
            }
        }
        // 如果没有找到标准CCID类，返回第一个接口（某些设备使用厂商自定义类）
        return if (device.interfaceCount > 0) device.getInterface(0) else null
    }

    /**
     * 构建IccPowerOn命令
     * CCID协议：PC_to_RDR_IccPowerOn
     */
    private fun buildIccPowerOnCommand(): ByteArray {
        return byteArrayOf(
            0x62.toByte(),  // bMessageType: PC_to_RDR_IccPowerOn
            0x00, 0x00, 0x00, 0x00,  // dwLength
            0x00,  // bSlot
            0x00,  // bSeq
            0x01,  // bPowerSelect: Activate (5V)
            0x00, 0x00  // RFU
        )
    }

    /**
     * 构建Get UID命令
     * ISO 14443-3 Type A: APDU命令
     */
    private fun buildGetUidCommand(): ByteArray {
        // XfrBlock命令包装APDU: FFCA000000
        val apdu = byteArrayOf(0xFF.toByte(), 0xCA.toByte(), 0x00, 0x00, 0x00)
        return buildXfrBlockCommand(apdu)
    }

    /**
     * 构建XfrBlock命令
     * CCID协议：PC_to_RDR_XfrBlock
     */
    private fun buildXfrBlockCommand(apdu: ByteArray): ByteArray {
        val header = byteArrayOf(
            0x6F.toByte(),  // bMessageType: PC_to_RDR_XfrBlock
            apdu.size.toByte(), 0x00, 0x00, 0x00,  // dwLength
            0x00,  // bSlot
            0x01,  // bSeq
            0x00,  // bBWI
            0x00, 0x00  // wLevelParameter
        )
        return header + apdu
    }

    /**
     * 发送命令并接收响应
     */
    private fun sendCommand(
        connection: UsbDeviceConnection,
        outEndpoint: UsbEndpoint,
        inEndpoint: UsbEndpoint,
        command: ByteArray
    ): ByteArray? {
        try {
            // 发送命令
            val bytesSent = connection.bulkTransfer(outEndpoint, command, command.size, 5000)
            if (bytesSent < 0) {
                Log.e(TAG, "Failed to send command")
                return null
            }

            // 接收响应
            val responseBuffer = ByteArray(1024)
            val bytesReceived = connection.bulkTransfer(inEndpoint, responseBuffer, responseBuffer.size, 5000)
            if (bytesReceived < 0) {
                Log.e(TAG, "Failed to receive response")
                return null
            }

            return responseBuffer.copyOf(bytesReceived)
        } catch (e: Exception) {
            Log.e(TAG, "Error sending command: ${e.message}", e)
            return null
        }
    }

    /**
     * 检查响应是否成功
     */
    private fun isSuccessResponse(response: ByteArray): Boolean {
        if (response.size < 10) return false
        // CCID响应：第7字节是bStatus，0x00表示成功
        return response[7] == 0x00.toByte()
    }

    /**
     * 提取ATR (Answer To Reset)
     */
    private fun extractATR(response: ByteArray): ByteArray {
        if (response.size < 10) return byteArrayOf()
        // CCID响应头10字节，之后是数据
        val dataLength = (response[1].toInt() and 0xFF) or 
                        ((response[2].toInt() and 0xFF) shl 8) or
                        ((response[3].toInt() and 0xFF) shl 16) or
                        ((response[4].toInt() and 0xFF) shl 24)
        
        if (dataLength == 0 || response.size < 10 + dataLength) return byteArrayOf()
        return response.copyOfRange(10, 10 + dataLength)
    }

    /**
     * 提取UID
     */
    private fun extractUid(response: ByteArray): ByteArray {
        if (response.size < 10) return byteArrayOf()
        val data = extractATR(response)  // 使用相同的数据提取方法
        
        // UID通常在响应数据的最后几个字节（去掉SW1 SW2）
        return if (data.size > 2) {
            data.copyOf(data.size - 2)
        } else {
            data
        }
    }

    /**
     * 从ATR中提取UID（后备方案）
     */
    private fun extractUidFromATR(atr: ByteArray): ByteArray {
        // 某些卡片的UID可能包含在ATR中
        // 这里返回ATR的部分内容作为标识
        return if (atr.size >= 4) atr.copyOfRange(0, minOf(7, atr.size)) else atr
    }

    /**
     * 识别卡片类型
     */
    private fun identifyCardType(atr: ByteArray): String {
        if (atr.isEmpty()) return "Unknown"
        
        // 根据ATR特征识别卡片类型
        val atrHex = atr.joinToString("") { "%02X".format(it) }
        
        return when {
            atrHex.contains("3B8F80") -> "Mifare Classic 1K"
            atrHex.contains("3B8B80") -> "Mifare Classic 4K"
            atrHex.contains("3B8980") -> "Mifare Ultralight"
            atrHex.contains("3B8A80") -> "Mifare DESFire"
            atr[0] == 0x3B.toByte() -> "ISO 14443 Type A"
            atr[0] == 0x3F.toByte() -> "ISO 14443 Type B"
            else -> "Smart Card"
        }
    }

    /**
     * 获取卡片容量
     */
    private fun getCardCapacity(cardType: String): String {
        return when (cardType) {
            "Mifare Classic 1K" -> "1KB"
            "Mifare Classic 4K" -> "4KB"
            "Mifare Ultralight" -> "512 bytes"
            "Mifare DESFire" -> "2KB-8KB"
            else -> "Unknown"
        }
    }

    /**
     * 格式化UID显示
     */
    private fun formatUid(uid: ByteArray): String {
        if (uid.isEmpty()) return "Unknown"
        return uid.joinToString(":") { "%02X".format(it) }
    }

    /**
     * 根据设备ID查找USB设备
     */
    private fun findDeviceById(deviceId: String): UsbDevice? {
        return usbManager?.deviceList?.values?.find {
            it.deviceId.toString() == deviceId
        }
    }

    /**
     * 关闭当前连接
     */
    private fun closeConnection() {
        currentConnection?.close()
        currentConnection = null
    }
}
