FROM debian:bookworm-slim

# Argumentos:
# --------------------------------------------------------------------------------------
ARG USER
ARG oh_my_zsh=https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh

USER root

# Instala dependências e o PostgreSQL:
# --------------------------------------------------------------------------------------
RUN apt update && apt install -y postgresql procps tor torsocks dos2unix git sudo vim \
zsh vim curl net-tools nftables && apt clean

# Removendo apt lists:
# NOTA: Ao remover não conseguirá instalar mais pacotes. Descomente caso não queira
# instalar mais pacotes em sua imagem.
# --------------------------------------------------------------------------------------
# RUN rm -rf /var/lib/apt/lists/*

# Cria um novo usuário no sistema:
# --------------------------------------------------------------------------------------
RUN useradd -ms /bin/zsh $USER && usermod -aG sudo,users,postgres,debian-tor $USER
RUN echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN chown -R ${USER}:${USER} /home/${USER}

# Instalado Starship:
# --------------------------------------------------------------------------------------
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# Copia scripts para o container:
# --------------------------------------------------------------------------------------
RUN mkdir -p /usr/local/entrypoint
COPY ./entrypoint/* /usr/local/entrypoint/
COPY ./config/nftables.conf /etc/nftables.conf
COPY ./config/pg_hba.conf /opt/pg_hba.conf
COPY ./config/postgresql.conf /opt/postgresql.conf
COPY ./config/torctl.sh /etc/init.d/torctl

# Dá permissão de execução aos scripts:
# --------------------------------------------------------------------------------------
RUN chmod +x /usr/local/entrypoint/entrypoint.sh /usr/local/entrypoint/sql.sh \
/usr/local/entrypoint/firewall.sh /etc/init.d/torctl

# Converte arquivos para LF (do sistema):
# --------------------------------------------------------------------------------------
RUN dos2unix /usr/local/entrypoint/entrypoint.sh /opt/pg_hba.conf /opt/postgresql.conf

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
COPY ./config/.zshrc /home/${USER}/.zshrc

# Define o entrypoint:
# --------------------------------------------------------------------------------------
ENTRYPOINT ["zsh", "/usr/local/entrypoint/entrypoint.sh"]
