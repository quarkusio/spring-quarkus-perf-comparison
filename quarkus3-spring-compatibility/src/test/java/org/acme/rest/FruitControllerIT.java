package org.acme.rest;

import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

import org.junit.jupiter.api.MethodOrderer.OrderAnnotation;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

import io.quarkus.test.junit.QuarkusIntegrationTest;

import io.restassured.http.ContentType;
import jakarta.ws.rs.core.Response.Status;

@QuarkusIntegrationTest
@TestMethodOrder(OrderAnnotation.class)
public class FruitControllerIT {
	private static final int DEFAULT_ORDER = 1;

	@Test
	@Order(DEFAULT_ORDER)
	public void getAll() {
		get("/fruits").then()
			.statusCode(Status.OK.getStatusCode())
			.contentType(ContentType.JSON)
			.body("$.size()", is(2))
			.body("[0].id", greaterThanOrEqualTo(1))
			.body("[0].name", is("Apple"))
			.body("[0].description", is("Hearty fruit"))
			.body("[1].id", greaterThanOrEqualTo(1))
			.body("[1].name", is("Pear"))
			.body("[1].description", is("Juicy fruit"));
	}

	@Test
	@Order(DEFAULT_ORDER)
	public void getFruitFound() {
		get("/fruits/Apple").then()
			.statusCode(Status.OK.getStatusCode())
			.contentType(ContentType.JSON)
			.body("id", greaterThanOrEqualTo(1))
			.body("name", is("Apple"))
			.body("description", is("Hearty fruit"));
	}

	@Test
	@Order(DEFAULT_ORDER)
	public void getFruitNotFound() {
		get("/fruits/Watermelon").then()
			.statusCode(Status.NOT_FOUND.getStatusCode());
	}

	@Test
	@Order(DEFAULT_ORDER + 1)
	public void addFruit() {
		get("/fruits").then()
			.body("$.size()", is(2));

		given()
			.contentType(ContentType.JSON)
			.body("{\"name\":\"Grapefruit\",\"description\":\"Summer fruit\"}")
			.when().post("/fruits")
			.then()
			.contentType(ContentType.JSON)
			.statusCode(Status.OK.getStatusCode())
			.body("id", greaterThanOrEqualTo(3))
			.body("name", is("Grapefruit"))
			.body("description", is("Summer fruit"));

		get("/fruits").then()
			.body("$.size()", is(3));
	}
}
