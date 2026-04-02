FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["src/DriveJournal.API/DriveJournal.API.csproj", "src/DriveJournal.API/"]
COPY ["src/DriveJournal.Application/DriveJournal.Application.csproj", "src/DriveJournal.Application/"]
COPY ["src/DriveJournal.Domain/DriveJournal.Domain.csproj", "src/DriveJournal.Domain/"]
COPY ["src/DriveJournal.Infrastructure/DriveJournal.Infrastructure.csproj", "src/DriveJournal.Infrastructure/"]
RUN dotnet restore "src/DriveJournal.API/DriveJournal.API.csproj"
COPY . .
WORKDIR "/src/src/DriveJournal.API"
RUN dotnet build "DriveJournal.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "DriveJournal.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DriveJournal.API.dll"]
