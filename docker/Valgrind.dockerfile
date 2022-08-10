FROM unafterthought/tree-sitter:ruby

RUN apt-get update
RUN apt-get install -y valgrind

ARG work_dir=/workdir
ENV TREE_SITTER_PARSERS=/tree-sitter-parsers

WORKDIR ${work_dir}
COPY . ${workdir}

RUN rm -rf tree-sitter-parsers
RUN gem update --system --no-document
RUN gem install rake-compiler
RUN bundle config set --local path './vendor'
RUN bundle install
RUN bundle exec rake clean compile

CMD ["bundle", "exec", "rake", "test:valgrind"]
