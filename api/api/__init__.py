from importlib.metadata import version

try:
    import icecream
except ImportError:
    icecream = None

# for debugging with IceCream
if icecream:
    icecream.install()

__version__ = version("ya-arch-sprint-2-project-api")
