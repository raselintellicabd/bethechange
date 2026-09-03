sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  }) {
    return switch (this) {
      ApiSuccess<T>(:final data) => success(data),
      ApiFailure<T>(:final message, :final statusCode) =>
        failure(message, statusCode),
    };
  }
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);

  final T data;
}

final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure({required this.message, this.statusCode, this.error});

  final String message;
  final int? statusCode;
  final Object? error;
}
