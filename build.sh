docker buildx build \
     --progress=plain \
     -t technicalguru/mailserver-postfix:latest \
     -t technicalguru/mailserver-postfix:3.7.11.3 \
     -t technicalguru/mailserver-postfix:3.7.11 \
     -t technicalguru/mailserver-postfix:3.7 \
     -t technicalguru/mailserver-postfix:3 \
     --push \
     --platform linux/amd64,linux/arm64 \

#docker build --progress=plain -t technicalguru/mailserver-postfix:latest .
