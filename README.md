# Tailscale DERP Server Docker Deployment

This repository contains a Docker-based deployment for a Tailscale DERP (Designated Encrypted Relay for Packets) server. DERP servers help Tailscale clients communicate when direct connections aren't possible due to NAT or firewalls.

## Features

- 🐳 **Docker-based deployment** with multi-stage build
- 🔒 **SSL/TLS support** with Let's Encrypt or manual certificates
- 📊 **Health checks** and monitoring capabilities
- 🔄 **Auto-restart** and container management
- 🚀 **GitHub Actions** for automated builds
- 📝 **Comprehensive logging** with configurable verbosity
- 🛡️ **Security hardened** with non-root user

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- A domain name (for production deployment)
- SSL certificates (for HTTPS)

### Basic Deployment

1. Clone this repository:
```bash
git clone <repository-url>
cd docker/derp
```

2. Copy the environment template:
```bash
cp .env.example .env
```

3. Edit the `.env` file with your configuration:
```bash
# Required: Your domain name
DERP_DOMAIN=your-domain.com
DERP_HOSTNAME=derp-server

# Certificate configuration
DERP_CERTMODE=manual  # or 'letsencrypt'
DERP_CERTDIR=/certs

# Optional: STUN configuration
DERP_STUN=true
DERP_STUN_PORT=3478
```

4. Place your SSL certificates in the `certs` directory:
```bash
mkdir -p certs
# Copy your certificate files:
# certs/your-domain.com.crt
# certs/your-domain.com.key
```

5. Start the DERP server:
```bash
docker-compose up -d
```

6. Check the status:
```bash
docker-compose logs -f derp
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DERP_DOMAIN` | `localhost` | Domain name for the DERP server |
| `DERP_CERTMODE` | `manual` | Certificate mode: `manual` or `letsencrypt` |
| `DERP_CERTDIR` | `/certs` | Directory containing SSL certificates |
| `DERP_HOSTNAME` | `derp-server` | Hostname for the server |
| `DERP_STUN` | `true` | Enable STUN server functionality |
| `DERP_STUN_PORT` | `3478` | STUN server port |
| `DERP_HTTP_PORT` | `80` | HTTP port |
| `DERP_HTTPS_PORT` | `443` | HTTPS port |
| `DERP_LOGFILE` | `/var/log/derper/derper.log` | Log file path |
| `DERP_VERBOSE` | `false` | Enable verbose logging |
| `DERP_VERIFY_CLIENTS` | `false` | Verify client certificates |

### Certificate Management

#### Manual Certificates

Place your certificate files in the `certs` directory:
- `certs/your-domain.com.crt` - SSL certificate
- `certs/your-domain.com.key` - SSL private key

#### Let's Encrypt (Automatic)

Set `DERP_CERTMODE=letsencrypt` in your `.env` file. The server will automatically obtain and renew certificates.

## Deployment Options

### Development Deployment

For local development and testing:

```bash
# Use the default configuration
docker-compose up -d
```

### Production Deployment

For production deployments with monitoring:

```bash
# Start with monitoring services
docker-compose --profile monitoring up -d
```

### Custom Deployment Scripts

Use the provided deployment scripts:

```bash
# Deploy to local Docker
./deploy.sh

# Deploy to GitHub Container Registry
./deploy-github.sh
```

## Networking

The DERP server exposes the following ports:

- **80/tcp** - HTTP (redirects to HTTPS)
- **443/tcp** - HTTPS (main DERP protocol)
- **3478/udp** - STUN server (optional)

Ensure these ports are open in your firewall and properly forwarded if running behind NAT.

## Monitoring and Health Checks

### Health Check Endpoint

The server provides a health check endpoint at:
```
http://your-domain.com/derp/probe
```

### Logs

View real-time logs:
```bash
# View DERP server logs
docker-compose logs -f derp

# View all service logs
docker-compose logs -f
```

### Container Status

Check container status:
```bash
# Check running containers
docker-compose ps

# Check resource usage
docker stats
```

## Tailscale Client Configuration

### Adding Your DERP Server

To use your custom DERP server with Tailscale clients, you need to configure a custom DERP map. Create a JSON file:

```json
{
  "Regions": {
    "900": {
      "RegionID": 900,
      "RegionCode": "custom",
      "RegionName": "Custom DERP",
      "Nodes": [
        {
          "Name": "custom-derp",
          "RegionID": 900,
          "HostName": "your-domain.com",
          "DERPPort": 443,
          "STUNPort": 3478
        }
      ]
    }
  }
}
```

### Client Configuration

Configure Tailscale clients to use your DERP server:

```bash
# Set custom DERP map
tailscale set --advertise-exit-node --derp-map-file=/path/to/derp-map.json
```

## Troubleshooting

### Common Issues

1. **Certificate errors**: Ensure your SSL certificates are valid and properly placed
2. **Port conflicts**: Check that ports 80, 443, and 3478 are not in use by other services
3. **DNS issues**: Verify your domain name resolves to the correct IP address
4. **Firewall blocking**: Ensure firewall rules allow traffic on required ports

### Debug Mode

Enable verbose logging for troubleshooting:

```bash
# Edit .env file
DERP_VERBOSE=true

# Restart the service
docker-compose restart derp
```

### Log Investigation

Check logs for issues:

```bash
# Check startup logs
docker-compose logs derp | head -50

# Follow real-time logs
docker-compose logs -f derp

# Check host system logs
journalctl -u docker
```

## GitHub Actions CI/CD

This repository includes GitHub Actions workflows for automated building and deployment:

- **Build and Test**: Automatically builds the Docker image on every push
- **Release**: Creates releases and pushes images to GitHub Container Registry
- **Security Scanning**: Scans Docker images for vulnerabilities

### Setting Up GitHub Actions

1. Enable GitHub Actions in your repository
2. Set up the following secrets in your repository settings:
   - `DOCKER_USERNAME` - Docker Hub username (optional)
   - `DOCKER_TOKEN` - Docker Hub access token (optional)

The workflow will automatically:
- Build the Docker image
- Run security scans
- Push to GitHub Container Registry
- Create releases for tagged commits

## Security Considerations

- 🔒 **Non-root container**: Runs as unprivileged user
- 🛡️ **Minimal base image**: Uses Alpine Linux for reduced attack surface
- 🔐 **SSL/TLS required**: All traffic encrypted
- 📝 **Audit logging**: Comprehensive logging for security monitoring
- 🚫 **No unnecessary services**: Only runs required components

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

- 📚 **Tailscale Docs**: https://tailscale.com/kb/
- 🐛 **Issues**: Report issues in this repository
- 💬 **Community**: Join the Tailscale community discussions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Tailscale team for the excellent DERP implementation
- Docker community for containerization best practices
- Alpine Linux for providing a secure, minimal base image