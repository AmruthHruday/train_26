from django.http import HttpResponse

def home(request):
    return HttpResponse(
        "<h1>Hello, Docker & Django World! 🐳🐍</h1>"
        "<p>Your Django web application is running successfully inside a Docker container!</p>"
    )
