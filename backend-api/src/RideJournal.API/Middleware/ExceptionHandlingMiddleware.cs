using System.Net;
using System.Text.Json;
using RideJournal.Application.Exceptions;

namespace RideJournal.API.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var (statusCode, response) = exception switch
        {
            ValidationException validationEx => (
                HttpStatusCode.BadRequest,
                new ErrorResponse("Validation failed", validationEx.Errors)),
            NotFoundException => (
                HttpStatusCode.NotFound,
                new ErrorResponse(exception.Message)),
            UnauthorizedException => (
                HttpStatusCode.Unauthorized,
                new ErrorResponse(exception.Message)),
            ForbiddenException => (
                HttpStatusCode.Forbidden,
                new ErrorResponse(exception.Message)),
            ConflictException => (
                HttpStatusCode.Conflict,
                new ErrorResponse(exception.Message)),
            _ => (
                HttpStatusCode.InternalServerError,
                new ErrorResponse("An unexpected error occurred."))
        };

        if (statusCode == HttpStatusCode.InternalServerError)
            _logger.LogError(exception, "Unhandled exception");

        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)statusCode;

        var json = JsonSerializer.Serialize(response, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        await context.Response.WriteAsync(json);
    }
}

public class ErrorResponse
{
    public string Message { get; set; }
    public IDictionary<string, string[]>? Errors { get; set; }

    public ErrorResponse(string message, IDictionary<string, string[]>? errors = null)
    {
        Message = message;
        Errors = errors;
    }
}
