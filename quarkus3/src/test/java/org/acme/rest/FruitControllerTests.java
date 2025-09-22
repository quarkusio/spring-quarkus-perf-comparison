package org.acme.rest;

import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.is;

import java.util.List;
import java.util.Optional;

import jakarta.ws.rs.core.Response.Status;

import org.acme.domain.Fruit;
import org.acme.repository.FruitRepository;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import io.quarkus.test.InjectMock;
import io.quarkus.test.junit.QuarkusTest;

import io.restassured.http.ContentType;

@QuarkusTest
class FruitControllerTests {
	@InjectMock
	FruitRepository fruitRepository;

	@Test
	public void getAll() {
		Mockito.when(this.fruitRepository.listAll())
			.thenReturn(List.of(new Fruit(1L, "Apple", "Hearty Fruit")));

		get("/fruits").then()
			.statusCode(Status.OK.getStatusCode())
			.contentType(ContentType.JSON)
			.body("$.size()", is(1))
			.body("[0].id", is(1))
			.body("[0].name", is("Apple"))
			.body("[0].description", is("Hearty Fruit"));

		Mockito.verify(this.fruitRepository).listAll();
		Mockito.verifyNoMoreInteractions(this.fruitRepository);
	}

	@Test
	public void getFruitFound() {
		Mockito.when(this.fruitRepository.findByName(Mockito.eq("Apple")))
			.thenReturn(Optional.of(new Fruit(1L, "Apple", "Hearty Fruit")));

		get("/fruits/Apple").then()
			.statusCode(Status.OK.getStatusCode())
			.contentType(ContentType.JSON)
			.body("id", is(1))
			.body("name", is("Apple"))
			.body("description", is("Hearty Fruit"));

		Mockito.verify(this.fruitRepository).findByName(Mockito.eq("Apple"));
		Mockito.verifyNoMoreInteractions(this.fruitRepository);
	}

	@Test
	public void getFruitNotFound() {
		Mockito.when(this.fruitRepository.findByName(Mockito.eq("Apple")))
			.thenReturn(Optional.empty());

		get("/fruits/Apple").then()
			.statusCode(Status.NOT_FOUND.getStatusCode());

		Mockito.verify(this.fruitRepository).findByName(Mockito.eq("Apple"));
		Mockito.verifyNoMoreInteractions(this.fruitRepository);
	}

	@Test
	public void addFruit() {
		Mockito.doNothing()
			.when(this.fruitRepository)
			.persist(Mockito.any(Fruit.class));

		given()
			.contentType(ContentType.JSON)
			.body("{\"name\":\"Grapefruit\",\"description\":\"Summer fruit\"}")
			.when().post("/fruits")
			.then()
			.contentType(ContentType.JSON)
			.statusCode(Status.OK.getStatusCode())
			.body("name", is("Grapefruit"))
			.body("description", is("Summer fruit"));

		Mockito.verify(this.fruitRepository).persist(Mockito.any(Fruit.class));
		Mockito.verifyNoMoreInteractions(this.fruitRepository);
	}
}
