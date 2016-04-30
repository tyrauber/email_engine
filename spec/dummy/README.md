# Ahoy Email Performance

This Rails Application provides a framework for instrumenting the performance of sending email with ActionMailer and AhoyEmail. A TestMailer and TestWorker is provided, along with a rake task to measure performance using benchmark-ips.

The rake task measures 3 things:

1) tracking open and click
2) tracking open, not click
3) tracking click, not open
4) tracking neither open or click

## Results

```
Warming up --------------------------------------
tracking open and click (deliver_now)
                         1.000  i/100ms
tracking open, not click (deliver_now)
                         1.000  i/100ms
tracking click, not open (deliver_now)
                         1.000  i/100ms
tracking neither open or click (deliver_now)
                         1.000  i/100ms
Calculating -------------------------------------
tracking open and click (deliver_now)
                          0.009  (± 0.0%) i/s -      1.000  in 108.925723s
tracking open, not click (deliver_now)
                          0.036  (± 0.0%) i/s -      1.000  in  27.761011s
tracking click, not open (deliver_now)
                          0.052  (± 0.0%) i/s -      1.000  in  19.280258s
tracking neither open or click (deliver_now)
                          0.044  (± 0.0%) i/s -      1.000  in  22.701992s

Comparison:
tracking click, not open (deliver_now):        0.1 i/s
tracking neither open or click (deliver_now):  0.0 i/s - 1.18x slower
tracking open, not click (deliver_now):        0.0 i/s - 1.44x slower
tracking open and click (deliver_now):         0.0 i/s - 5.65x slower
```

## Instructions

1) Clone the repo, `git clone git://github.com/tyrauber/ahoy_email_performance`
2) Run `bundle install`
3) Run `rake ahoy_email:performance[1000,50]`
