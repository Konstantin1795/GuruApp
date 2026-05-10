<?php

namespace App\Support\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

/**
 * If an API route returns HTML (error page, redirect body, nginx), the mobile client
 * fails with JSON parse errors. Replace with a stable JSON error for api/*.
 */
final class RejectHtmlApiResponses
{
    public function handle(Request $request, Closure $next): Response
    {
        /** @var Response $response */
        $response = $next($request);

        if (! $this->isApiRequest($request)) {
            return $response;
        }

        if (! $this->responseLooksLikeHtml($response)) {
            return $response;
        }

        $requestId = (string) ($request->headers->get('X-Request-Id') ?: Str::uuid());
        $status = $response->getStatusCode() >= 400 ? $response->getStatusCode() : 502;

        return response()->json([
            'ok' => false,
            'error' => [
                'message' => 'Сервер вернул HTML вместо JSON. Проверьте URL API (/api), авторизацию и что backend доступен.',
                'type' => 'UnexpectedHtmlResponse',
            ],
            'meta' => [
                'request_id' => $requestId,
            ],
        ], $status, ['Content-Type' => 'application/json', 'X-Request-Id' => $requestId]);
    }

    private function isApiRequest(Request $request): bool
    {
        if ($request->expectsJson()) {
            return true;
        }

        $path = trim($request->path(), '/');

        return str_starts_with($path, 'api/') || $request->is('api/*');
    }

    /**
     * HTML часто приходит с неверным Content-Type (например application/json) — смотрим и заголовок, и тело.
     */
    private function responseLooksLikeHtml(Response $response): bool
    {
        $contentType = strtolower((string) $response->headers->get('Content-Type', ''));
        if (str_contains($contentType, 'text/html')) {
            return true;
        }

        $body = $response->getContent();
        if (! is_string($body) || $body === '') {
            return false;
        }

        $trim = ltrim($body);
        if ($trim === '') {
            return false;
        }

        $probe = strtolower(substr($trim, 0, 96));

        return str_starts_with($trim, '<')
            || str_starts_with($probe, '<!doctype')
            || str_starts_with($probe, '<html')
            || str_starts_with($probe, '<head')
            || str_starts_with($probe, '<body');
    }
}
