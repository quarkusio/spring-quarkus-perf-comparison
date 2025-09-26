package org.acme.rest;

import static io.restassured.RestAssured.get;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.is;

import java.math.BigDecimal;

import jakarta.ws.rs.core.Response.Status;

import org.junit.jupiter.api.MethodOrderer.OrderAnnotation;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

import io.quarkus.test.junit.QuarkusIntegrationTest;

import io.restassured.http.ContentType;

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
      .body("[0].storePrices[0].price", is(BigDecimal.valueOf(1.29).floatValue()))
      .body("[0].storePrices[0].store.name", is("Store 1"))
      .body("[0].storePrices[0].store.address.address", is("123 Main St"))
      .body("[0].storePrices[0].store.address.city", is("Anytown"))
      .body("[0].storePrices[0].store.address.country", is("USA"))
      .body("[0].storePrices[0].store.currency", is("USD"))
      .body("[0].storePrices[1].price", is(BigDecimal.valueOf(2.49).floatValue()))
      .body("[0].storePrices[1].store.name", is("Store 2"))
      .body("[0].storePrices[1].store.address.address", is("456 Main St"))
      .body("[0].storePrices[1].store.address.city", is("Paris"))
      .body("[0].storePrices[1].store.address.country", is("France"))
      .body("[0].storePrices[1].store.currency", is("EUR"))
			.body("[1].id", greaterThanOrEqualTo(1))
			.body("[1].name", is("Pear"))
			.body("[1].description", is("Juicy fruit"))
      .body("[1].storePrices[0].price", is(BigDecimal.valueOf(0.99).floatValue()))
      .body("[1].storePrices[0].store.name", is("Store 1"))
      .body("[1].storePrices[0].store.address.address", is("123 Main St"))
      .body("[1].storePrices[0].store.address.city", is("Anytown"))
      .body("[1].storePrices[0].store.address.country", is("USA"))
      .body("[1].storePrices[0].store.currency", is("USD"))
      .body("[1].storePrices[1].price", is(BigDecimal.valueOf(1.19).floatValue()))
      .body("[1].storePrices[1].store.name", is("Store 2"))
      .body("[1].storePrices[1].store.address.address", is("456 Main St"))
      .body("[1].storePrices[1].store.address.city", is("Paris"))
      .body("[1].storePrices[1].store.address.country", is("France"))
      .body("[1].storePrices[1].store.currency", is("EUR"));
	}

	@Test
	@Order(DEFAULT_ORDER)
	public void getFruitFound() {
		get("/fruits/Apple").then()
			.statusCode(Status.OK.getStatusCode())
			.contentType(ContentType.JSON)
			.body("id", greaterThanOrEqualTo(1))
			.body("name", is("Apple"))
			.body("description", is("Hearty fruit"))
      .body("storePrices[0].price", is(BigDecimal.valueOf(1.29).floatValue()))
      .body("storePrices[0].store.name", is("Store 1"))
      .body("storePrices[0].store.address.address", is("123 Main St"))
      .body("storePrices[0].store.address.city", is("Anytown"))
      .body("storePrices[0].store.address.country", is("USA"))
      .body("storePrices[0].store.currency", is("USD"))
      .body("storePrices[1].price", is(BigDecimal.valueOf(2.49).floatValue()))
      .body("storePrices[1].store.name", is("Store 2"))
      .body("storePrices[1].store.address.address", is("456 Main St"))
      .body("storePrices[1].store.address.city", is("Paris"))
      .body("storePrices[1].store.address.country", is("France"))
      .body("storePrices[1].store.currency", is("EUR"));
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
