<?php

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->api(append: [
            \App\Support\Http\Middleware\ForceJsonResponse::class,
            \App\Support\Http\Middleware\RequestId::class,
            \App\Support\Http\Middleware\RejectHtmlApiResponses::class,
        ]);

        $middleware->redirectGuestsTo(function (Request $request) {
            $path = trim($request->path(), '/');
            $isApi = $request->expectsJson()
                || str_starts_with($path, 'api/')
                || $request->is('api/*');

            return $isApi ? null : '/login';
        });
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (\Throwable $e, Request $request) {
            $path = trim($request->path(), '/');
            $isApi = $request->expectsJson()
                || str_starts_with($path, 'api/')
                || $request->is('api/*');

            if (! $isApi) {
                return null;
            }

            $status = match (true) {
                $e instanceof \Illuminate\Auth\AuthenticationException => Response::HTTP_UNAUTHORIZED,
                $e instanceof \Illuminate\Auth\Access\AuthorizationException => Response::HTTP_FORBIDDEN,
                $e instanceof \Illuminate\Validation\ValidationException => Response::HTTP_UNPROCESSABLE_ENTITY,
                $e instanceof \App\Modules\Operations\Exceptions\InvalidOperationTransitionException => Response::HTTP_UNPROCESSABLE_ENTITY,
                $e instanceof \Illuminate\Database\Eloquent\ModelNotFoundException => Response::HTTP_NOT_FOUND,
                $e instanceof \Symfony\Component\HttpKernel\Exception\HttpExceptionInterface => $e->getStatusCode(),
                default => Response::HTTP_INTERNAL_SERVER_ERROR,
            };

            $error = [
                'message' => $e instanceof \Illuminate\Validation\ValidationException
                    ? 'Validation failed.'
                    : ($e->getMessage() ?: Response::$statusTexts[$status] ?? 'Server error.'),
                'type' => class_basename($e::class),
            ];

            if ($e instanceof \Illuminate\Validation\ValidationException) {
                $error['fields'] = $e->errors();
            }

            if (config('app.debug')) {
                $error['exception'] = $e::class;
                $error['trace'] = collect($e->getTrace())->take(5)->all();
            }

            $requestId = (string) ($request->headers->get('X-Request-Id') ?: Str::uuid());

            return response()->json([
                'ok' => false,
                'error' => $error,
                'meta' => [
                    'request_id' => $requestId,
                ],
            ], $status);
        });
    })
    ->withSchedule(function (Schedule $schedule): void {
        $schedule->command('operations:complete-expired-transfer-waiting')->everyMinute();
        $schedule->command('operations:complete-expired-income-waiting')->everyMinute();
        $schedule->command('operations:complete-expired-report-waiting')->everyMinute();
    })
    ->create();