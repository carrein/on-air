/// Shared parameters for media file processing (image and video).
class ProcessFileParams {
  final String tempFilePath;
  final String finalFilePath;
  final String channelDir;

  ProcessFileParams({
    required this.tempFilePath,
    required this.finalFilePath,
    required this.channelDir,
  });
}
