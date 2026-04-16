class DeviceSnapshot {
  const DeviceSnapshot({
    required this.deviceHash,
    required this.fingerprintSignature,
    required this.installTimestamp,
    required this.installId,
    required this.attributes,
  });

  final String deviceHash;
  final String fingerprintSignature;
  final int installTimestamp;
  final String installId;
  final Map<String, String> attributes;

  String get shortDeviceHash => deviceHash.length <= 12
      ? deviceHash
      : '${deviceHash.substring(0, 6)}...${deviceHash.substring(deviceHash.length - 6)}';

  String get shortFingerprintSignature => fingerprintSignature.length <= 12
      ? fingerprintSignature
      : '${fingerprintSignature.substring(0, 6)}...${fingerprintSignature.substring(fingerprintSignature.length - 6)}';
}
