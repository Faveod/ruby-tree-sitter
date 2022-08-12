FROM unafterthought/tree-sitter:ruby

RUN apt-get update
RUN apt-get install -y clang

ARG work_dir=/workdir
ENV TREE_SITTER_PARSERS=/tree-sitter-parsers

WORKDIR ${work_dir}
COPY . ${work_dir}

RUN rm -rf tree-sitter-parsers
RUN gem update --system --no-document
RUN gem install rake-compiler
RUN bundle config set --local path './vendor'
RUN bundle install

# RUN ls -lah | grep asan && sleep 10
ENV CC=clang
ENV CXX=clang++
ENV SANITIZE=1
ENV ASAN_OPTIONS=halt_on_error=0:abort_on_error=0:fast_unwind_on_malloc=1:detect_leaks=1
ENV UBSAN_OPTIONS=print_stacktrace=1
RUN bundle exec rake clean compile

# RUN ln -s ./lsanignore /usr/bin/lsanignore
ENV LSAN_OPTIONS=suppressions=${work_dir}/.lsanignore
ENV LD_PRELOAD=libasan.so.6
CMD ["bundle", "exec", "rake", "test"]
