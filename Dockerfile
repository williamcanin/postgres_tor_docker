FROM debian:bookworm-slim

# Argumentos:
# --------------------------------------------------------------------------------------
ARG USER
ARG oh_my_zsh=https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh

USER root

# Instala dependências e o PostgreSQL:
# --------------------------------------------------------------------------------------
RUN apt-get update && \
apt-get install -y postgresql supervisor dos2unix git sudo vim zsh vim curl net-tools \
nftables && apt-get clean && rm -rf /var/lib/apt/lists/*

# Cria um novo usuário no sistema:
# --------------------------------------------------------------------------------------
RUN useradd -ms /bin/zsh $USER && usermod -aG sudo,users,postgres $USER
RUN echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN chown -R ${USER}:${USER} /home/${USER}

# Instalado Starship:
# --------------------------------------------------------------------------------------
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# Copia scripts para o container:
# --------------------------------------------------------------------------------------
RUN mkdir -p /usr/local/entrypoint
COPY ./entrypoint/* /usr/local/entrypoint/
COPY nftables.conf /etc/nftables.conf
COPY pg_hba.conf /opt/pg_hba.conf
COPY postgresql.conf /opt/postgresql.conf

# Dá permissão de execução aos scripts:
# --------------------------------------------------------------------------------------
RUN chmod +x /usr/local/entrypoint/entrypoint.sh /usr/local/entrypoint/sql.sh \
/usr/local/entrypoint/firewall.sh

# Converte arquivos para LF (do sistema):
# --------------------------------------------------------------------------------------
RUN dos2unix /usr/local/bin/entrypoint.sh /opt/pg_hba.conf /opt/postgresql.conf

# Entra no usuário criado:
# --------------------------------------------------------------------------------------
USER $USER

# Instala o Oh-My-ZSH e plugins (opcional):
# --------------------------------------------------------------------------------------
RUN sh -c "$(curl -fsSL $oh_my_zsh)"
RUN echo "eval \"\$(starship init zsh)\"" > \
/home/${USER}/.oh-my-zsh/custom/themes/starship.zsh-theme
RUN git clone https://github.com/zsh-users/zsh-autosuggestions \
${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
COPY .zshrc /home/${USER}/.zshrc

# Define o entrypoint:
# --------------------------------------------------------------------------------------
ENTRYPOINT ["zsh", "/usr/local/entrypoint/entrypoint.sh"]
