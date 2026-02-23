export function sseEvent(event: string, data: unknown): string {
  return `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
}

export const SSE_HEADERS = {
  "Content-Type": "text/event-stream; charset=utf-8",
  "Cache-Control": "no-cache, no-transform",
  Connection: "keep-alive",
};

export function sseError(errorCode: string, message: string, requestId: string): string {
  return sseEvent("error", {
    error_code: errorCode,
    message,
    request_id: requestId,
  });
}
