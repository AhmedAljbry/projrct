class DeviceFingerprint {
  const DeviceFingerprint({
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
}
