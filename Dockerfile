FROM continuumio/miniconda3

LABEL maintainer="Eduardo Gonzalez-Solares <eglez@ast.cam.ac.uk>"

USER root

ARG env=environment.yml

RUN echo "deb http://deb.debian.org/debian stretch contrib" >> /etc/apt/sources.list.d/contrib.list

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libc6-dev procps libxrender1 vim texlive-latex-base texlive-latex-extra dvipng && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64
RUN chmod +x /usr/local/bin/dumb-init

COPY $env /root/environment.yml

RUN conda env update -n base -f /root/environment.yml && \
    conda clean -tipsy && \
    /opt/conda/bin/jupyter serverextension enable --py nbserverproxy && \
    /opt/conda/bin/jupyter labextension install @jupyterlab/hub-extension && \
    /opt/conda/bin/jupyter labextension install jupyterlab_bokeh @pyviz/jupyterlab_pyviz jupyter-matplotlib && \
    /opt/conda/bin/jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    /opt/conda/bin/jupyter labextension install dask-labextension && \
    /opt/conda/bin/jupyter labextension install @jupyterlab/toc @jupyterlab/github && \
    /opt/conda/bin/jupyter labextension install jupyter-leaflet @jupyter-widgets/jupyterlab-sidecar @jupyterlab/fasta-extension && \
    npm cache clean --force && \
    rm -rf /opt/conda/share/jupyter/lab/staging && \
    rm -rf /root/.cache/yarn && \
    rm -rf /root/.node-gyp

RUN mkdir -p /opt/conda/share/jupyter/lab/settings && \
    echo '{ "hub_prefix": "/jupyter" }' > /opt/conda/share/jupyter/lab/settings/page_config.json

RUN mkdir /opt/app
ADD jupyterlab_imaxt /opt/app/jupyterlab_imaxt
RUN cd /opt/app/jupyterlab_imaxt && jupyter labextension install 

ADD ipython /etc/ipython

COPY prepare.sh /usr/bin/prepare.sh
RUN chmod +x /usr/bin/prepare.sh

RUN groupadd -g 1110 jimaxt && \
    groupadd -g 1111 imaxt && \
    groupadd -g 3785 docker
RUN useradd -m -u 1110 -g jimaxt jimaxt && \
    useradd -m -u 1111 -g imaxt imaxt && \
    usermod -a -G docker jimaxt

USER jimaxt

ENV XDG_CACHE_HOME /home/jimaxt/.cache/
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot"

WORKDIR /home/jimaxt

ENTRYPOINT ["/usr/local/bin/dumb-init", "/usr/bin/prepare.sh"]
