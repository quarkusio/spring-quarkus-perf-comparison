package org.acme.e2e;

import static io.restassured.RestAssured.get;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.is;

import jakarta.ws.rs.core.Response.Status;

import org.junit.jupiter.api.MethodOrderer.OrderAnnotation;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

import io.quarkus.test.junit.QuarkusIntegrationTest;

import io.restassured.http.ContentType;


// Note: There isn't an equivalent of this test in the Spring projects.
// It tests the application as a prod mode application, from a different process.
// Because the process is not shared and the application is run in prod mode, the database is empty initially.
@QuarkusIntegrationTest
@TestMethodOrder(OrderAnnotation.class)
public class FruitControllerIT {
	private static final int DEFAULT_ORDER = 1;

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
                .body("$.size()", is(0));

        given()
                .contentType(ContentType.JSON)
                .body("{\"name\":\"Pomelo\",\"description\":\"Exotic fruit\"}")
                .when().post("/fruits")
                .then()
                .contentType(ContentType.JSON)
                .statusCode(Status.OK.getStatusCode())
                .body("id", greaterThanOrEqualTo(1))
                .body("name", is("Pomelo"))
                .body("description", is("Exotic fruit"));

        get("/fruits").then()
                .body("$.size()", is(1));
    }


	@Test
	@Order(DEFAULT_ORDER+2)
	public void getFruitFound() {
		get("/fruits/Pomelo").then()
			.statusCode(Status.OK.getStatusCode())
			.contentType(ContentType.JSON)
			.body("id", greaterThanOrEqualTo(1))
			.body("name", is("Pomelo"))
			.body("description", is("Exotic fruit"));
	}

    @Test
    @Order(DEFAULT_ORDER+3)
    public void getAll() {
        get("/fruits").then()
                .statusCode(Status.OK.getStatusCode())
                .contentType(ContentType.JSON)
                .body("$.size()", is(1))
                .body("[0].id", greaterThanOrEqualTo(1))
                .body("[0].name", is("Pomelo"))
                .body("[0].description", is("Exotic fruit"));
    }

}
