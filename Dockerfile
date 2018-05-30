FROM rabbitmq:3.7

RUN rabbitmq-plugins enable --offline rabbitmq_management
RUN rabbitmq-plugins enable --offline rabbitmq_peer_discovery_k8s
# extract "rabbitmqadmin" from inside the "rabbitmq_management-X.Y.Z.ez" plugin zipfile
# see https://github.com/docker-library/rabbitmq/issues/207
RUN set -eux; \
    erl -noinput -eval ' \
        { ok, AdminBin } = zip:foldl(fun(FileInArchive, GetInfo, GetBin, Acc) -> \
            case Acc of \
                "" -> \
                    case lists:suffix("/rabbitmqadmin", FileInArchive) of \
                        true -> GetBin(); \
                        false -> Acc \
                    end; \
                _ -> Acc \
            end \
        end, "", init:get_plain_arguments()), \
        io:format("~s", [ AdminBin ]), \
        init:stop(). \
    ' -- /plugins/rabbitmq_management-*.ez > /usr/local/bin/rabbitmqadmin; \
    [ -s /usr/local/bin/rabbitmqadmin ]; \
    chmod +x /usr/local/bin/rabbitmqadmin; \
    apt-get update; \
    apt-get install -y --no-install-recommends python; \
    rm -rf /var/lib/apt/lists/*; \
    rabbitmqadmin --version

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends wget; \
    rm -rf /var/lib/apt/lists/*; \
    cd /usr/lib/rabbitmq/lib/rabbitmq_server-3.7.5/plugins; \
    wget --no-check-certificate https://github.com/Ayanda-D/rabbitmq-queue-master-balancer/releases/download/v0.0.3/rabbitmq_queue_master_balancer-0.0.3.ez

RUN rabbitmq-plugins enable --offline rabbitmq_queue_master_balancer

EXPOSE 15671 15672