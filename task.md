# Add backend to the app

I have flutter app that tracks rides which works locally on device.
I want to add backend to the app so that rides can be synced between devices.

## Requirements

- Add registration and authentication
  - Users can register via google oauth or emai
- Add ride synchronization between devices
- Users can be found and followed
- Each user can edit only their own rides
- Followed user view in rides view other people rides
- Users have their own profile picture

## Architecture

- Backend should be written in c#
- Database should be mongodb
- Use clean architecture
- Use dependency injection
- Use SOLID principles
- Use CQRS pattern
- Use MediatR for handling requests
- Use AutoMapper for mapping objects
- Use FluentValidation for validation
- Use MongoDB for database
- Use Docker for containerization
- Use Docker Compose for containerization
- Github actions for testing
- Backend should be source of truth and frontend should be client (wherever possible, we still want to support offline mode, so when syncing rides we should still prioritize edited data on device if done at a later date than on server)
- Support JWT authentication and authorization

## Notes

- Backend should be fully tested wherever possible and meaningful
- Start project in separate folder named "backend-api"
- If ypu find any issues or alternative better ways to handle something please let me know
- Idea is to have backend on server with flutter web version running as frontend and then mobile app clients, at some point user will be able to share rides via link (if user sets ride to visibility public, visibility will be private, only followers and public) so keep that in mind and add configuration for flutter to connect to the right endpoint
- Add .gitignore file
