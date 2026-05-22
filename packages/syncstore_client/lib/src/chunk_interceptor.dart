import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pool/pool.dart';
import 'package:uuid/uuid.dart';

class ConcurrentChunkInterceptor extends Interceptor {
  final int threshold;
  final int chunkSize;

  ConcurrentChunkInterceptor({
    this.threshold = 16 * 1024, // 16KB
    this.chunkSize = 16 * 1024, // 16KB
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['isChunked'] != true || options.data is! Uint8List || options.method.toUpperCase() != 'POST') {
      // print('Data is not Uint8List or chunking not enabled, skipping chunk interceptor.');
      return handler.next(options);
    }

    final Uint8List fullData = options.data;
    if (fullData.length <= threshold) return handler.next(options);

    final totalSize = fullData.length;
    final totalChunks = (totalSize / chunkSize).ceil();
    final uploadId = Uuid().v4();
    print("Starting chunked upload: totalSize=$totalSize bytes, totalChunks=$totalChunks, uploadId=$uploadId");

    // calculate and update global progress
    final pool = Pool(4); // limit concurrency to 4
    final Map<int, int> sentBytesMap = {};
    void updateGlobalProgress() {
      if (options.onSendProgress != null) {
        int totalSent = sentBytesMap.values.fold(0, (sum, v) => sum + v);
        options.onSendProgress!(totalSent, totalSize);
        print("Global progress: ${(totalSent / totalSize * 100).toStringAsFixed(2)}%");
      }
    }

    try {
      final chunkDio = Dio(BaseOptions(baseUrl: options.baseUrl));

      final List<Response> allResponses = await pool.forEach<int, Response>(Iterable<int>.generate(totalChunks), (
        i,
      ) async {
        final start = i * chunkSize;
        final end = (start + chunkSize > totalSize) ? totalSize : start + chunkSize;
        final chunk = fullData.sublist(start, end);

        final res = await chunkDio.post(
          options.path,
          data: chunk,
          options: Options(
            headers: {
              ...options.headers,
              'X-Upload-ID': uploadId,
              'X-Chunk-Index': i.toString(),
              'X-Chunk-Total': totalChunks.toString(),
            },
          ),
          onSendProgress: (sent, _) {
            sentBytesMap[i] = sent;
            updateGlobalProgress();
          },
        );

        print("Chunk $i uploaded, status: ${res.statusCode}");
        return res;
      }).toList();
      final finalResponse = allResponses.lastWhere((res) => res.statusCode != 202, orElse: () => allResponses.last);
      // sleep for a while to wait for server to finalize the upload
      await Future.delayed(Duration(milliseconds: 100 * totalChunks));
      handler.resolve(finalResponse);
    } catch (e) {
      handler.reject(DioException(requestOptions: options, error: e.toString()));
    }
  }
}
