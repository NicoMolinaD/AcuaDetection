from fastapi import HTTPException, status

class MalcomException(Exception):
    def __init__(self, message: str, status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)

class NotFoundException(MalcomException):
    def __init__(self, message: str = "Recurso no encontrado"):
        super().__init__(message, status.HTTP_404_NOT_FOUND)

class UnauthorizedException(MalcomException):
    def __init__(self, message: str = "No autorizado"):
        super().__init__(message, status.HTTP_401_UNAUTHORIZED)

class ForbiddenException(MalcomException):
    def __init__(self, message: str = "Acceso denegado"):
        super().__init__(message, status.HTTP_403_FORBIDDEN)

class BadRequestException(MalcomException):
    def __init__(self, message: str = "Solicitud incorrecta"):
        super().__init__(message, status.HTTP_400_BAD_REQUEST)
