
import logging, sys
logging.basicConfig(stream=sys.stderr)

sys.path.insert(0, "/root/osrs-stocks")

from flask_app import app as application
