# API-only image: builds and runs the .NET API (no web frontend).
# Build context is the repo root. For the combined web + API image, see Dockerfile.prod.

# --- Stage 1: build & publish the .NET API ---
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["backend-api/src/RideJournal.API/RideJournal.API.csproj", "src/RideJournal.API/"]
COPY ["backend-api/src/RideJournal.Application/RideJournal.Application.csproj", "src/RideJournal.Application/"]
COPY ["backend-api/src/RideJournal.Domain/RideJournal.Domain.csproj", "src/RideJournal.Domain/"]
COPY ["backend-api/src/RideJournal.Infrastructure/RideJournal.Infrastructure.csproj", "src/RideJournal.Infrastructure/"]
RUN dotnet restore "src/RideJournal.API/RideJournal.API.csproj"
COPY backend-api/ .
WORKDIR "/src/src/RideJournal.API"
RUN dotnet publish "RideJournal.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# --- Stage 2: runtime image (API only) ---
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
EXPOSE 8080
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "RideJournal.API.dll"]
