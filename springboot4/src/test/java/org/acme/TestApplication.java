package org.acme;

import org.springframework.boot.SpringApplication;

public class TestApplication {
	public static void main(String[] args) {
		SpringApplication
			.from(SpringBoot4Application::main)
			.with(ContainersConfig.class)
			.run(args);
	}
}
