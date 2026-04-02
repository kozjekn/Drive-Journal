FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["src/RideJournal.API/RideJournal.API.csproj", "src/RideJournal.API/"]
COPY ["src/RideJournal.Application/RideJournal.Application.csproj", "src/RideJournal.Application/"]
COPY ["src/RideJournal.Domain/RideJournal.Domain.csproj", "src/RideJournal.Domain/"]
COPY ["src/RideJournal.Infrastructure/RideJournal.Infrastructure.csproj", "src/RideJournal.Infrastructure/"]
RUN dotnet restore "src/RideJournal.API/RideJournal.API.csproj"
COPY . .
WORKDIR "/src/src/RideJournal.API"
RUN dotnet build "RideJournal.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "RideJournal.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "RideJournal.API.dll"]
